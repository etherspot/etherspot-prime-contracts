// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC20Actions} from "../../test/ERC20Actions.sol";
import {IValidator, MODULE_TYPE_VALIDATOR, VALIDATION_FAILED} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";

import "forge-std/console2.sol";

contract ERC20SessionKeyValidator is IValidator {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    event ERC20SKV_SessionKeyEnabled(address sessionKey, address wallet);
    event ERC20SKV_SessionKeyDisabled(address sessionKey, address wallet);
    error ERC20SKV_InvalidSessionKey();
    error ERC20SKV_SessionPaused(address sessionKey);
    error ERC20SKV_UnsuportedToken();
    error ERC20SKV_UnsupportedSelector(bytes4 selectorUsed);
    error ERC20SKV_UnsupportedInterface();
    error ERC20SKV_SessionKeySpendLimitExceeded();
    error ERC20SKV_ExceedsExecutorSpendCap(uint256 total, uint256 spendCap);
    error ERC20SKV_InsufficientApprovalAmount();
    event ERC20SKV_ExecutorSpendCapReduced(uint256 amount, uint256 newCap);
    event ERC20SKV_SessionKeySpentLimitReduced(
        uint256 amount,
        uint256 newLimit
    );
    error NotImplemented();

    mapping(address wallet => address[] assocSessionKeys)
        public walletSessionKeys;
    mapping(address sessionKey => mapping(address wallet => SessionData))
        public sessionData;

    struct SessionData {
        address token;
        bytes4 interfaceId;
        bytes4 funcSelector;
        uint256 spendingLimit;
        uint48 validAfter;
        uint48 validUntil;
        bool paused;
    }

    function enableSessionKey(bytes calldata _sessionData) public {
        address sessionKey = address(bytes20(_sessionData[0:20]));
        address token = address(bytes20(_sessionData[20:40]));
        bytes4 interfaceId = bytes4(_sessionData[40:44]);
        bytes4 funcSelector = bytes4(_sessionData[44:48]);
        uint256 spendingLimit = uint256(bytes32(_sessionData[48:80]));
        uint48 validAfter = uint48(bytes6(_sessionData[80:86]));
        uint48 validUntil = uint48(bytes6(_sessionData[86:92]));
        if (!_validateSelector(funcSelector))
            revert ERC20SKV_UnsupportedSelector(funcSelector);
        sessionData[sessionKey][msg.sender] = SessionData(
            token,
            interfaceId,
            funcSelector,
            spendingLimit,
            validAfter,
            validUntil,
            false
        );
        walletSessionKeys[msg.sender].push(sessionKey);
        emit ERC20SKV_SessionKeyEnabled(sessionKey, msg.sender);
    }

    function disableSessionKey(address _session) public {
        delete sessionData[_session][msg.sender];
        emit ERC20SKV_SessionKeyDisabled(_session, msg.sender);
    }

    function rotateSessionKey(
        address _oldSessionKey,
        bytes calldata _newSessionData
    ) external {
        disableSessionKey(_oldSessionKey);
        enableSessionKey(_newSessionData);
    }

    function toggleSessionKeyPause(address _sessionKey) external {
        SessionData storage sd = sessionData[_sessionKey][msg.sender];
        sd.paused = !sd.paused;
    }

    function checkSessionKeyPaused(
        address _sessionKey
    ) public view returns (bool paused) {
        return sessionData[_sessionKey][msg.sender].paused;
    }

    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public returns (bool valid) {
        bytes calldata callData = userOp.callData;
        console2.logBytes(callData);
        (
            bytes4 selector,
            address target,
            address to,
            address from,
            uint256 amount
        ) = _digest(callData);

        console2.logBytes4(selector);
        console2.log("target contract:", target);
        console2.log("to:", to);
        console2.log("from:", from);
        console2.log("amount:", amount);

        SessionData storage sd = sessionData[_sessionKey][msg.sender];
        if (sd.validUntil == 0 || sd.validUntil < block.timestamp)
            revert ERC20SKV_InvalidSessionKey();
        if (target != sd.token) revert ERC20SKV_UnsuportedToken();
        console2.logBytes4(sd.interfaceId);

        if (IERC165(target).supportsInterface(sd.interfaceId) == false)
            revert ERC20SKV_UnsupportedInterface();
        console2.logBytes4(sd.funcSelector);
        console2.logBytes4(selector);
        if (selector != sd.funcSelector)
            revert ERC20SKV_UnsupportedSelector(selector);
        console2.log("amount:", amount);
        console2.log("spendingLimit:", sd.spendingLimit);
        if (amount > sd.spendingLimit)
            revert ERC20SKV_SessionKeySpendLimitExceeded();
        if (checkSessionKeyPaused(_sessionKey))
            revert ERC20SKV_SessionPaused(_sessionKey);
        sd.spendingLimit = sd.spendingLimit - amount;
        emit ERC20SKV_SessionKeySpentLimitReduced(amount, sd.spendingLimit);
        console2.log("VALIDATION OF SESSION KEY PARAMS PASSED!");
        return true;
    }

    function getAssociatedSessionKeys()
        public
        view
        returns (address[] memory keys)
    {
        return walletSessionKeys[msg.sender];
    }

    function getSessionKeyData(
        address _sessionKey
    ) public view returns (SessionData memory data) {
        return sessionData[_sessionKey][msg.sender];
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256 validationData) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(userOpHash);
        address recovered = ECDSA.recover(hash, userOp.signature);
        if (!validateSessionKeyParams(recovered, userOp))
            return VALIDATION_FAILED;
        SessionData storage sd = sessionData[recovered][msg.sender];
        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }

    function isModuleType(
        uint256 moduleTypeId
    ) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function onInstall(bytes calldata data) external override {}

    function onUninstall(bytes calldata data) external override {
        // Clean up
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4) {
        revert NotImplemented();
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        revert NotImplemented();
    }

    function _validateSelector(bytes4 _selector) internal pure returns (bool) {
        bytes4[] memory allowedSigs = new bytes4[](4);
        allowedSigs[0] = IERC20.approve.selector;
        allowedSigs[1] = IERC20.transfer.selector;
        allowedSigs[2] = IERC20.transferFrom.selector;
        allowedSigs[3] = ERC20Actions.transferERC20Action.selector;
        for (uint256 i; i < allowedSigs.length; i++) {
            if (_selector == allowedSigs[i]) {
                return true;
            }
        }
        return false;
    }

    function _digest(
        bytes calldata _data
    )
        internal
        pure
        returns (
            bytes4 selector,
            address targetContract,
            address to,
            address from,
            uint256 amount
        )
    {
        bytes4 functionSelector;
        assembly {
            functionSelector := calldataload(_data.offset)
            targetContract := calldataload(add(_data.offset, 0x04))
        }
        if (
            functionSelector == IERC20.approve.selector ||
            functionSelector == IERC20.transfer.selector ||
            functionSelector == ERC20Actions.transferERC20Action.selector
        ) {
            assembly {
                targetContract := calldataload(add(_data.offset, 0x04))
                to := calldataload(add(_data.offset, 0x24))
                amount := calldataload(add(_data.offset, 0x44))
            }
            console2.log("targetContract:", targetContract);
            console2.log("to:", to);
            console2.log("amount:", amount);
            return (functionSelector, targetContract, to, address(0), amount);
        } else if (functionSelector == IERC20.transferFrom.selector) {
            assembly {
                targetContract := calldataload(add(_data.offset, 0x04))
                from := calldataload(add(_data.offset, 0x24))
                to := calldataload(add(_data.offset, 0x44))
                amount := calldataload(add(_data.offset, 0x64))
            }
            console2.log("targetContract:", targetContract);
            console2.log("to:", to);
            console2.log("from:", from);
            console2.log("amount:", amount);
            return (functionSelector, targetContract, to, from, amount);
        } else {
            revert ERC20SKV_UnsupportedSelector(functionSelector);
        }
    }
}
