// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {MODULE_TYPE_VALIDATOR, VALIDATION_FAILED} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import {IERC20SessionKeyValidator} from "../../interfaces/IERC20SessionKeyValidator.sol";
import {ERC20Actions} from "../executors/ERC20Actions.sol";
import {ArrayLib} from "../../libraries/ArrayLib.sol";

contract ERC20SessionKeyValidator is IERC20SessionKeyValidator {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                  CONSTANTS                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    string constant NAME = "ERC20SessionKeyValidator";
    string constant VERSION = "1.0.0";

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    ERRORS                 */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    error ERC20SKV_ModuleAlreadyInstalled();
    error ERC20SKV_ModuleNotInstalled();
    error ERC20SKV_InvalidSessionKey();
    error ERC20SKV_InvalidToken();
    error ERC20SKV_InvalidInterfaceId();
    error ERC20SKV_InvalidFunctionSelector();
    error ERC20SKV_InvalidSpendingLimit();
    error ERC20SKV_InvalidDuration(uint256 validAfter, uint256 validUntil);
    error ERC20SKV_SessionKeyAlreadyExists(address sessionKey);
    error ERC20SKV_SessionKeyDoesNotExist(address session);
    error ERC20SKV_SessionPaused(address sessionKey);
    error ERC20SKV_UnsuportedToken();
    error ERC20SKV_UnsupportedInterface();
    error ERC20SKV_UnsupportedSelector(bytes4 selectorUsed);
    error ERC20SKV_SessionKeySpendLimitExceeded();
    error NotImplemented();

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   MAPPINGS                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    mapping(address => bool) public initialized;
    mapping(address wallet => address[] assocSessionKeys)
        public walletSessionKeys;
    mapping(address sessionKey => mapping(address wallet => SessionData))
        public sessionData;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*               PUBLIC/EXTERNAL             */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    // @inheritdoc IERC20SessionKeyValidator
    function enableSessionKey(bytes calldata _sessionData) public {
        address sessionKey = address(bytes20(_sessionData[0:20]));
        if (sessionKey == address(0)) revert ERC20SKV_InvalidSessionKey();
        if (
            sessionData[sessionKey][msg.sender].validUntil != 0 &&
            ArrayLib._contains(getAssociatedSessionKeys(), sessionKey)
        ) revert ERC20SKV_SessionKeyAlreadyExists(sessionKey);
        address token = address(bytes20(_sessionData[20:40]));
        if (token == address(0)) revert ERC20SKV_InvalidToken();
        bytes4 interfaceId = bytes4(_sessionData[40:44]);
        if (interfaceId == bytes4(0)) revert ERC20SKV_InvalidInterfaceId();
        bytes4 funcSelector = bytes4(_sessionData[44:48]);
        if (funcSelector == bytes4(0))
            revert ERC20SKV_InvalidFunctionSelector();
        uint256 spendingLimit = uint256(bytes32(_sessionData[48:80]));
        if (spendingLimit == 0) revert ERC20SKV_InvalidSpendingLimit();
        uint48 validAfter = uint48(bytes6(_sessionData[80:86]));
        uint48 validUntil = uint48(bytes6(_sessionData[86:92]));
        if (validUntil <= validAfter || validUntil == 0 || validAfter == 0)
            revert ERC20SKV_InvalidDuration(validAfter, validUntil);
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

    // @inheritdoc IERC20SessionKeyValidator
    function disableSessionKey(address _session) public {
        if (sessionData[_session][msg.sender].validUntil == 0)
            revert ERC20SKV_SessionKeyDoesNotExist(_session);
        delete sessionData[_session][msg.sender];
        walletSessionKeys[msg.sender] = ArrayLib._removeElement(
            getAssociatedSessionKeys(),
            _session
        );
        emit ERC20SKV_SessionKeyDisabled(_session, msg.sender);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function rotateSessionKey(
        address _oldSessionKey,
        bytes calldata _newSessionData
    ) external {
        disableSessionKey(_oldSessionKey);
        enableSessionKey(_newSessionData);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function toggleSessionKeyPause(address _sessionKey) external {
        SessionData memory sd = sessionData[_sessionKey][msg.sender];
        if (sd.paused) {
            sessionData[_sessionKey][msg.sender].paused = false;
            emit ERC20SKV_SessionKeyUnpaused(_sessionKey, msg.sender);
        } else {
            sessionData[_sessionKey][msg.sender].paused = true;
            emit ERC20SKV_SessionKeyPaused(_sessionKey, msg.sender);
        }
    }

    // @inheritdoc IERC20SessionKeyValidator
    function checkSessionKeyPaused(
        address _sessionKey
    ) public view returns (bool) {
        return sessionData[_sessionKey][msg.sender].paused;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public returns (bool) {
        bytes calldata callData = userOp.callData;
        (
            bytes4 selector,
            address target,
            address to,
            address from,
            uint256 amount
        ) = _digest(callData);

        SessionData memory sd = sessionData[_sessionKey][msg.sender];
        if (target != sd.token) revert ERC20SKV_UnsuportedToken();
        if (IERC165(target).supportsInterface(sd.interfaceId) == false)
            revert ERC20SKV_UnsupportedInterface();
        if (selector != sd.funcSelector)
            revert ERC20SKV_UnsupportedSelector(selector);
        if (amount > sd.spendingLimit)
            revert ERC20SKV_SessionKeySpendLimitExceeded();
        if (checkSessionKeyPaused(_sessionKey))
            revert ERC20SKV_SessionPaused(_sessionKey);
        return true;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function getAssociatedSessionKeys() public view returns (address[] memory) {
        return walletSessionKeys[msg.sender];
    }

    // @inheritdoc IERC20SessionKeyValidator
    function getSessionKeyData(
        address _sessionKey
    ) public view returns (SessionData memory) {
        return sessionData[_sessionKey][msg.sender];
    }

    // @inheritdoc IERC20SessionKeyValidator
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256) {
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(userOpHash);
        address sessionKeySigner = ECDSA.recover(ethHash, userOp.signature);

        if (!validateSessionKeyParams(sessionKeySigner, userOp))
            return VALIDATION_FAILED;
        SessionData memory sd = sessionData[sessionKeySigner][msg.sender];
        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function isModuleType(
        uint256 moduleTypeId
    ) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function onInstall(bytes calldata data) external override {
        if (initialized[msg.sender] == true)
            revert ERC20SKV_ModuleAlreadyInstalled();
        initialized[msg.sender] = true;
        emit ERC20SKV_ModuleInstalled(msg.sender);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function onUninstall(bytes calldata data) external override {
        if (initialized[msg.sender] == false)
            revert ERC20SKV_ModuleNotInstalled();
        address[] memory sessionKeys = getAssociatedSessionKeys();
        uint256 sessionKeysLength = sessionKeys.length;
        for (uint256 i; i < sessionKeysLength; i++) {
            delete sessionData[sessionKeys[i]][msg.sender];
        }
        delete walletSessionKeys[msg.sender];
        initialized[msg.sender] = false;
        emit ERC20SKV_ModuleUninstalled(msg.sender);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4) {
        revert NotImplemented();
    }

    // @inheritdoc IERC20SessionKeyValidator
    function isInitialized(address smartAccount) external view returns (bool) {
        return initialized[smartAccount];
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   INTERNAL                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

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
