// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {MODULE_TYPE_VALIDATOR, VALIDATION_FAILED, VALIDATION_SUCCESS} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
// import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";
import {IERC20SessionKeyValidator} from "../../interfaces/IERC20SessionKeyValidator.sol";
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
    error ERC20SKV_InvalidFunctionSelector();
    error ERC20SKV_InvalidSpendingLimit();
    error ERC20SKV_InvalidDuration(uint256 validAfter, uint256 validUntil);
    error ERC20SKV_SessionKeyAlreadyExists(address sessionKey);
    error ERC20SKV_SessionKeyDoesNotExist(address session);
    error ERC20SKV_SessionPaused(address sessionKey);
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
        bytes4 funcSelector = bytes4(_sessionData[40:44]);
        if (funcSelector == bytes4(0))
            revert ERC20SKV_InvalidFunctionSelector();
        uint256 spendingLimit = uint256(bytes32(_sessionData[44:76]));
        if (spendingLimit == 0) revert ERC20SKV_InvalidSpendingLimit();
        uint48 validAfter = uint48(bytes6(_sessionData[76:82]));
        uint48 validUntil = uint48(bytes6(_sessionData[82:88]));
        if (validUntil <= validAfter || validUntil == 0 || validAfter == 0)
            revert ERC20SKV_InvalidDuration(validAfter, validUntil);
        sessionData[sessionKey][msg.sender] = SessionData(
            token,
            funcSelector,
            spendingLimit,
            validAfter,
            validUntil,
            true
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
        SessionData storage sd = sessionData[_sessionKey][msg.sender];
        if (sd.validUntil == 0)
            revert ERC20SKV_SessionKeyDoesNotExist(_sessionKey);
        if (sd.live) {
            sd.live = false;
            emit ERC20SKV_SessionKeyPaused(_sessionKey, msg.sender);
        } else {
            sd.live = true;
            emit ERC20SKV_SessionKeyUnpaused(_sessionKey, msg.sender);
        }
    }

    // @inheritdoc IERC20SessionKeyValidator
    function checkSessionKeyPaused(
        address _sessionKey
    ) public view returns (bool) {
        return !sessionData[_sessionKey][msg.sender].live;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public returns (bool) {
        SessionData memory sd = sessionData[_sessionKey][msg.sender];
        if (checkSessionKeyPaused(_sessionKey)) return false;
        address target;
        bytes calldata callData = userOp.callData;
        bytes4 sel = bytes4(callData[:4]);
        if (sel == IERC7579Account.execute.selector) {
            ModeCode mode = ModeCode.wrap(bytes32(callData[4:36]));
            (CallType calltype, , , ) = ModeLib.decode(mode);
            if (calltype == CALLTYPE_SINGLE) {
                bytes calldata execData;
                // 0x00 ~ 0x04 : selector
                // 0x04 ~ 0x24 : mode code
                // 0x24 ~ 0x44 : execution target
                // 0x44 ~0x64 : execution value
                // 0x64 ~ : execution calldata
                (target, , execData) = ExecutionLib.decodeSingle(
                    callData[100:]
                );
                (
                    bytes4 selector,
                    address from,
                    address to,
                    uint256 amount
                ) = _digest(execData);
                if (target != sd.token) return false;
                if (selector != sd.funcSelector) return false;
                if (amount > sd.spendingLimit) return false;
                return true;
            }
            if (calltype == CALLTYPE_BATCH) {
                Execution[] calldata execs = ExecutionLib.decodeBatch(
                    callData[100:]
                );
                for (uint256 i; i < execs.length; i++) {
                    target = execs[i].target;
                    (
                        bytes4 selector,
                        address from,
                        address to,
                        uint256 amount
                    ) = _digest(execs[i].callData);
                    if (target != sd.token) return false;
                    if (selector != sd.funcSelector) return false;
                    if (amount > sd.spendingLimit) return false;
                }
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
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
        address sessionKeySigner = ECDSA.recover(userOpHash, userOp.signature);
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
        view
        returns (bytes4 selector, address from, address to, uint256 amount)
    {
        selector = bytes4(_data[0:4]);
        if (
            selector == IERC20.approve.selector ||
            selector == IERC20.transfer.selector
        ) {
            to = address(bytes20(_data[16:36]));
            amount = uint256(bytes32(_data[36:68]));
            return (selector, address(0), to, amount);
        } else if (selector == IERC20.transferFrom.selector) {
            from = address(bytes20(_data[16:36]));
            to = address(bytes20(_data[48:68]));
            amount = uint256(bytes32(_data[68:100]));
            return (selector, from, to, amount);
        } else {
            return (bytes4(0), address(0), address(0), 0);
        }
    }
}
