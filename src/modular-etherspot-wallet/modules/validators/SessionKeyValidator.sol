// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {MODULE_TYPE_VALIDATOR, VALIDATION_FAILED} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";

import {IValidator} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import {ArrayLib} from "../../libraries/ArrayLib.sol";

contract SessionKeyValidator is IValidator {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   STRUCTS                 */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    struct GenericSessionData {
        address target; // The target contract address.
        bytes4 selector; // The function selector for the allowed operation.
        uint256 spendingLimit; // The maximum amount that can be spent with this session key per tx.
        uint48 validAfter; // The timestamp after which the session key is valid.
        uint48 validUntil; // The timestamp until which the session key is valid.
        bool paused; // Flag indicating whether the session key is paused or not.
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                  CONSTANTS                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    string constant NAME = "SessionKeyValidator";
    string constant VERSION = "1.0.0";

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   EVENTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    event SKV_ModuleInstalled(address wallet);
    event SKV_ModuleUninstalled(address wallet);
    event SKV_SessionKeyEnabled(address sessionKey, address wallet);
    event SKV_SessionKeyDisabled(address sessionKey, address wallet);
    event SKV_SessionKeyPaused(address sessionKey, address wallet);
    event SKV_SessionKeyUnpaused(address sessionKey, address wallet);

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    ERRORS                 */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    error SKV_ModuleAlreadyInstalled();
    error SKV_ModuleNotInstalled();
    error SKV_InvalidSessionKey();
    error SKV_InvalidTarget();
    error SKV_InvalidInterfaceId();
    error SKV_InvalidFunctionSelector();
    error SKV_InvalidSpendingLimit();
    error SKV_InvalidDuration(uint256 validAfter, uint256 validUntil);
    error SKV_SessionKeyAlreadyExists(address sessionKey);
    error SKV_SessionKeyDoesNotExist(address session);
    error SKV_SessionPaused(address sessionKey);
    error SKV_UnsuportedTarget();
    error SKV_UnsupportedInterface();
    error SKV_UnsupportedSelector(bytes4 selectorUsed);
    error SKV_SessionKeySpendLimitExceeded();
    error NotImplemented();

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   MAPPINGS                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    mapping(address => bool) public initialized;
    mapping(address wallet => address[] assocSessionKeys)
        public walletSessionKeys;
    mapping(address sessionKey => mapping(address wallet => GenericSessionData))
        public sessionData;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*               PUBLIC/EXTERNAL             */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function enableSessionKey(bytes calldata _sessionData) public {
        address sessionKey = address(bytes20(_sessionData[0:20]));
        if (sessionKey == address(0)) revert SKV_InvalidSessionKey();
        if (
            sessionData[sessionKey][msg.sender].validUntil != 0 &&
            ArrayLib._contains(getAssociatedSessionKeys(), sessionKey)
        ) revert SKV_SessionKeyAlreadyExists(sessionKey);
        address tar = address(bytes20(_sessionData[20:40]));
        if (tar == address(0)) revert SKV_InvalidTarget();
        bytes4 sel = bytes4(_sessionData[40:44]);
        if (sel == bytes4(0)) revert SKV_InvalidFunctionSelector();
        uint256 spendingLimit = uint256(bytes32(_sessionData[44:76]));
        if (spendingLimit == 0) revert SKV_InvalidSpendingLimit();
        uint48 validAfter = uint48(bytes6(_sessionData[76:82]));
        uint48 validUntil = uint48(bytes6(_sessionData[82:88]));
        if (validUntil <= validAfter || validUntil == 0 || validAfter == 0)
            revert SKV_InvalidDuration(validAfter, validUntil);
        sessionData[sessionKey][msg.sender] = GenericSessionData(
            tar,
            sel,
            spendingLimit,
            validAfter,
            validUntil,
            false
        );
        walletSessionKeys[msg.sender].push(sessionKey);
        emit SKV_SessionKeyEnabled(sessionKey, msg.sender);
    }

    function disableSessionKey(address _session) public {
        if (sessionData[_session][msg.sender].validUntil == 0)
            revert SKV_SessionKeyDoesNotExist(_session);
        delete sessionData[_session][msg.sender];
        walletSessionKeys[msg.sender] = ArrayLib._removeElement(
            getAssociatedSessionKeys(),
            _session
        );
        emit SKV_SessionKeyDisabled(_session, msg.sender);
    }

    function rotateSessionKey(
        address _oldSessionKey,
        bytes calldata _newSessionData
    ) external {
        disableSessionKey(_oldSessionKey);
        enableSessionKey(_newSessionData);
    }

    function toggleSessionKeyPause(address _sessionKey) external {
        GenericSessionData memory sd = sessionData[_sessionKey][msg.sender];
        if (sd.paused) {
            sessionData[_sessionKey][msg.sender].paused = false;
            emit SKV_SessionKeyUnpaused(_sessionKey, msg.sender);
        } else {
            sessionData[_sessionKey][msg.sender].paused = true;
            emit SKV_SessionKeyPaused(_sessionKey, msg.sender);
        }
    }

    function checkSessionKeyPaused(
        address _sessionKey
    ) public view returns (bool) {
        return sessionData[_sessionKey][msg.sender].paused;
    }

    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public returns (bool) {
        bytes calldata callData = userOp.callData;

        GenericSessionData memory sd = sessionData[_sessionKey][msg.sender];
        if (address(bytes20(callData[4:24])) != sd.target)
            revert SKV_UnsuportedTarget();
        if (bytes4(callData[0:4]) != sd.selector)
            revert SKV_UnsupportedSelector(bytes4(callData[0:4]));
        // check in backend
        // if (amount > sd.spendingLimit)
        //     revert SKV_SessionKeySpendLimitExceeded();
        if (checkSessionKeyPaused(_sessionKey))
            revert SKV_SessionPaused(_sessionKey);
        return true;
    }

    function getAssociatedSessionKeys() public view returns (address[] memory) {
        return walletSessionKeys[msg.sender];
    }

    function getSessionKeyData(
        address _sessionKey
    ) public view returns (GenericSessionData memory) {
        return sessionData[_sessionKey][msg.sender];
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256) {
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(userOpHash);
        address sessionKeySigner = ECDSA.recover(ethHash, userOp.signature);

        if (!validateSessionKeyParams(sessionKeySigner, userOp))
            return VALIDATION_FAILED;
        GenericSessionData memory sd = sessionData[sessionKeySigner][
            msg.sender
        ];
        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }

    function isModuleType(
        uint256 moduleTypeId
    ) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function onInstall(bytes calldata data) external override {
        if (initialized[msg.sender] == true)
            revert SKV_ModuleAlreadyInstalled();
        initialized[msg.sender] = true;
        emit SKV_ModuleInstalled(msg.sender);
    }

    function onUninstall(bytes calldata data) external override {
        if (initialized[msg.sender] == false) revert SKV_ModuleNotInstalled();
        address[] memory sessionKeys = getAssociatedSessionKeys();
        uint256 sessionKeysLength = sessionKeys.length;
        for (uint256 i; i < sessionKeysLength; i++) {
            delete sessionData[sessionKeys[i]][msg.sender];
        }
        delete walletSessionKeys[msg.sender];
        initialized[msg.sender] = false;
        emit SKV_ModuleUninstalled(msg.sender);
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4) {
        revert NotImplemented();
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        return initialized[smartAccount];
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   INTERNAL                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    // function _digest(
    //     bytes calldata _data
    // )
    //     internal
    //     pure
    //     returns (
    //         bytes4 selector,
    //         address targetContract,
    //         address to,
    //         address from,
    //         uint256 amount
    //     )
    // {
    //     bytes4 functionSelector;
    //     assembly {
    //         functionSelector := calldataload(_data.offset)
    //         targetContract := calldataload(add(_data.offset, 0x04))
    //     }
    //     if (
    //         functionSelector == IERC20.approve.selector ||
    //         functionSelector == IERC20.transfer.selector ||
    //         functionSelector == ERC20Actions.transferERC20Action.selector
    //     ) {
    //         assembly {
    //             targetContract := calldataload(add(_data.offset, 0x04))
    //             to := calldataload(add(_data.offset, 0x24))
    //             amount := calldataload(add(_data.offset, 0x44))
    //         }
    //         return (functionSelector, targetContract, to, address(0), amount);
    //     } else if (functionSelector == IERC20.transferFrom.selector) {
    //         assembly {
    //             targetContract := calldataload(add(_data.offset, 0x04))
    //             from := calldataload(add(_data.offset, 0x24))
    //             to := calldataload(add(_data.offset, 0x44))
    //             amount := calldataload(add(_data.offset, 0x64))
    //         }
    //         return (functionSelector, targetContract, to, from, amount);
    //     } else {
    //         revert SKV_UnsupportedSelector(functionSelector);
    //     }
    // }
}
