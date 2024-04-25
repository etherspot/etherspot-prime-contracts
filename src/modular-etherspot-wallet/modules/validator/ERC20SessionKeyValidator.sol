// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IValidator, IHook, MODULE_TYPE_VALIDATOR, MODULE_TYPE_HOOK, VALIDATION_FAILED} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";

import "forge-std/console2.sol";

contract ERC20SessionKeyValidator is IValidator, IHook {
    error ERC20SKV_PaymasterNotSet();
    error ERC20SKV_InvalidPaymaster();
    error ERC20SKV_InvalidSessionKey();
    error ERC20SKV_SessionPaused(address sessionKey);
    error ERC20SKV_UnsuportedToken();
    error ERC20SKV_UnsupportedSelector(bytes4 selectorUsed);
    error ERC20SKV_SessionKeySpendLimitExceeded();
    error ERC20SKV_ExecutorSpendCapExceeded();
    error ERC20SKV_InsufficientApprovalAmount();
    event ERC20SKV_ExecutorSpendCapReduced(uint256 amount, uint256 newCap);
    event ERC20SKV_SessionKeySpentLimitReduced(
        uint256 amount,
        uint256 newLimit
    );
    error NotImplemented();

    event SessionKeyEnabled(address sessionKey, address wallet);

    mapping(address wallet => address[] assocSessionKeys)
        public walletSessionKeys;
    mapping(address sessionKey => mapping(address wallet => SessionData))
        public sessionData;
    mapping(address wallet => uint256 spendingCap) public executorSpendCap;
    mapping(address wallet => address sessionKey) /*transient*/
        public tmpSession;

    struct SessionData {
        address token;
        bytes4 funcSelector;
        uint256 spendingLimit;
        uint48 validAfter;
        uint48 validUntil;
        bool paused;
    }

    function enableSessionKey(bytes calldata _sessionData) public {
        address sessionKey = address(bytes20(_sessionData[0:20]));
        address token = address(bytes20(_sessionData[20:40]));
        bytes4 funcSelector = bytes4(_sessionData[40:44]);
        uint256 spendingLimit = uint256(bytes32(_sessionData[44:76]));
        uint48 validAfter = uint48(bytes6(_sessionData[76:82]));
        uint48 validUntil = uint48(bytes6(_sessionData[82:88]));
        if (!_validateSelector(funcSelector))
            revert ERC20SKV_UnsupportedSelector(funcSelector);
        sessionData[sessionKey][msg.sender] = SessionData(
            token,
            funcSelector,
            spendingLimit,
            validAfter,
            validUntil,
            false
        );
        walletSessionKeys[msg.sender].push(sessionKey);
        emit SessionKeyEnabled(sessionKey, msg.sender);
    }

    function disableSessionKey(address _session) public {
        delete sessionData[_session][msg.sender];
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
        if (selector != sd.funcSelector)
            revert ERC20SKV_UnsupportedSelector(selector);
        if (amount > sd.spendingLimit)
            revert ERC20SKV_SessionKeySpendLimitExceeded();
        if (checkSessionKeyPaused(_sessionKey))
            revert ERC20SKV_SessionPaused(_sessionKey);
        console2.log("spendLimit pre adj:", sd.spendingLimit);
        console2.log("amount to reduce spendLimit by:", amount);
        sd.spendingLimit = sd.spendingLimit - amount;
        console2.log("spendLimit post adj:", sd.spendingLimit);
        emit ERC20SKV_SessionKeySpentLimitReduced(amount, sd.spendingLimit);

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
        console2.log(
            "Storing the session key against the wallet in transient storage:",
            recovered
        );
        tmpSession[msg.sender] = recovered;
        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }

    function isModuleType(
        uint256 moduleTypeId
    ) external pure override returns (bool) {
        return
            moduleTypeId == MODULE_TYPE_VALIDATOR ||
            moduleTypeId == MODULE_TYPE_HOOK;
    }

    function onInstall(bytes calldata data) external override {
        if (data.length <= 68) return;
        uint256 offset = 4;
        offset += 64;
        uint256 execSpendCap = abi.decode(data[offset:], (uint256));
        executorSpendCap[msg.sender] = execSpendCap;
        // TODO: add event
    }

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

    function isInitialized(address _mew) external view returns (bool) {
        revert NotImplemented();
    }

    function preCheck(
        address msgSender,
        bytes calldata msgData
    ) external override returns (bytes memory hookData) {
        console2.log("ESKV - preCheck called");
        // bytes4 functionSelector;
        // uint256 value;
        // address targetContract;
        // bytes4 operation;
        // address initiator;
        // address recipient;
        // uint256 amount;
        // uint256 gasLimit;
        // assembly {
        //     functionSelector := calldataload(msgData.offset)
        //     value := calldataload(add(msgData.offset, 0x04))
        //     targetContract := calldataload(add(msgData.offset, 0x24))
        //     operation := calldataload(add(msgData.offset, 0x44))
        //     initiator := calldataload(add(msgData.offset, 0x64))
        //     recipient := calldataload(add(msgData.offset, 0x84))
        //     amount := calldataload(add(msgData.offset, 0xa4))
        //     gasLimit := calldataload(add(msgData.offset, 0xc4))
        // }
        // console2.logBytes4(functionSelector);
        // console2.log("value:", value);
        // console2.log("target contract:", targetContract);
        // console2.logBytes4(operation);
        // console2.log("initiator:", initiator);
        // console2.log("recipient:", recipient);
        // console2.log("amount:", amount);
        // console2.log("gasLimit:", gasLimit);
        // //////////////////////////
        /////////////////////////
        // ModeCode mode = ModeCode.wrap(bytes32(msgData[4:36]));
        // (CallType callType, ExecType execType, , ) = mode.decode(mode);
        console2.logBytes(msgData[68 + 32:]);
        return msgData[68 + 32:];
        // return abi.encodePacked(callType, msgData[68 + 32:]);
    }

    function postCheck(
        bytes calldata hookData
    ) external override returns (bool success) {
        console2.log("ESKV - postCheck called");

        // address target = address(bytes20(execData[0:20]));
        // uint256 value = uint256(bytes32(execData[20:52]));
        // bytes calldata callData = execData[52:];
        // console2.log("target contract:", target);
        // console2.log("value:", value);
        // console2.logBytes(callData);
        bytes calldata callData = hookData[52:];
        console2.log("HOOK DATA");
        console2.logBytes(callData);

        bytes4 selector;
        address from;
        address to;
        uint256 amount;
        assembly {
            selector := calldataload(callData.offset)
            from := calldataload(add(callData.offset, 0x04))
            to := calldataload(add(callData.offset, 0x24))
            amount := calldataload(add(callData.offset, 0x44))
        }

        console2.logBytes4(selector);
        console2.log("to:", to);
        console2.log("from:", from);
        console2.log("amount:", amount);
        // address sender = abi.decode(hookData, (address));
        address sk = tmpSession[from];
        console2.log("session key addr:", sk);
        if (sk == address(0)) {
            console2.log("sk is address(0)");
            console2.log("executorSpendCap is", executorSpendCap[from]);
            if (amount > executorSpendCap[from]) {
                revert ERC20SKV_ExecutorSpendCapExceeded();
            } else {
                executorSpendCap[from] = executorSpendCap[from] - amount;
                console2.log("executorSpendCap is", executorSpendCap[from]);
                emit ERC20SKV_ExecutorSpendCapReduced(
                    amount,
                    executorSpendCap[from]
                );
            }
            // } else {
            //     SessionData storage sd = sessionData[sk][from];
            //     console2.log("spendLimit pre adj:", sd.spendingLimit);
            //     console2.log("amount to reduce spendLimit by:", amount);
            //     sd.spendingLimit = sd.spendingLimit - amount;
            //     console2.log("spendLimit post adj:", sd.spendingLimit);
            //     emit ERC20SKV_SessionKeySpentLimitReduced(amount, sd.spendingLimit);
        }
        return true;
    }

    function _validateSelector(bytes4 _selector) internal view returns (bool) {
        bytes4[] memory allowedSigs = new bytes4[](3);
        allowedSigs[0] = IERC20.approve.selector;
        allowedSigs[1] = IERC20.transfer.selector;
        allowedSigs[2] = IERC20.transferFrom.selector;
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
        view
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
        }
        if (functionSelector == IERC20.approve.selector) {
            assembly {
                targetContract := calldataload(add(_data.offset, 0x04))
                to := calldataload(add(_data.offset, 0x24))
                amount := calldataload(add(_data.offset, 0x44))
            }
            return (functionSelector, targetContract, address(0), to, amount);
        } else if (functionSelector == IERC20.transfer.selector) {
            assembly {
                targetContract := calldataload(add(_data.offset, 0x04))
                to := calldataload(add(_data.offset, 0x24))
                amount := calldataload(add(_data.offset, 0x44))
            }
            return (functionSelector, targetContract, to, address(0), amount);
        } else if (functionSelector == IERC20.transferFrom.selector) {
            assembly {
                targetContract := calldataload(add(_data.offset, 0x04))
                from := calldataload(add(_data.offset, 0x24))
                to := calldataload(add(_data.offset, 0x44))
                amount := calldataload(add(_data.offset, 0x64))
            }
            return (functionSelector, targetContract, to, from, amount);
        } else {
            revert ERC20SKV_UnsupportedSelector(functionSelector);
        }
    }
}
