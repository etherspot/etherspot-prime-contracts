// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IValidator, MODULE_TYPE_VALIDATOR, VALIDATION_FAILED} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";
import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";

import "forge-std/console2.sol";

contract SimpleSessionKeyValidator is IValidator {
    error SSKV_PaymasterNotSet();
    error SSKV_InvalidPaymaster();
    error SSKV_InvalidSessionKey();
    error SSKV_SessionPaused(address sessionKey);
    error SSKV_UnsupportedSelector();
    error NotImplemented();

    mapping(address wallet => address[] assocSessionKeys)
        public walletSessionKeys;
    mapping(address sessionKey => mapping(address wallet => SessionData))
        public sessionData;

    struct SessionData {
        bytes4 funcSelector;
        uint48 validAfter;
        uint48 validUntil;
        bool paused;
    }

    function enableSessionKey(bytes calldata _sessionData) public {
        address sessionKey = address(bytes20(_sessionData[0:20]));
        bytes4 funcSelector = bytes4(_sessionData[20:24]);
        uint48 validAfter = uint48(bytes6(_sessionData[24:30]));
        uint48 validUntil = uint48(bytes6(_sessionData[30:36]));
        sessionData[sessionKey][msg.sender] = SessionData(
            funcSelector,
            validAfter,
            validUntil,
            false
        );
        walletSessionKeys[msg.sender].push(sessionKey);
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

    function checkValidSessionKey(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public view returns (bool valid) {
        SessionData storage sd = sessionData[_sessionKey][msg.sender];
        if (sd.validUntil == 0 || sd.validUntil < block.timestamp)
            revert SSKV_InvalidSessionKey();
        if (bytes4(userOp.callData[0:4]) != sd.funcSelector)
            revert SSKV_UnsupportedSelector();
        if (checkSessionKeyPaused(_sessionKey))
            revert SSKV_SessionPaused(_sessionKey);
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
        console2.log("userop.sender", userOp.sender);
        console2.log("HERE 1");
        console2.log("recovered", ECDSA.recover(hash, userOp.signature));
        console2.log("HERE 2");

        address recovered = ECDSA.recover(hash, userOp.signature);
        console2.log("HERE 3");

        if (!checkValidSessionKey(recovered, userOp)) return VALIDATION_FAILED;
        SessionData storage sd = sessionData[recovered][msg.sender];
        // if (bytes4(userOp.callData[0:4]) != sd.funcSelector)
        //     revert SSKV_UnsupportedSelector();
        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }

    function validateSignature(
        bytes32 hash,
        bytes calldata signature
    ) public view returns (uint256 validationData) {
        address recovered = ECDSA.recover(hash, signature);
        SessionData storage sd = sessionData[recovered][msg.sender];
        if (sd.validUntil != 0) {
            return _packValidationData(false, sd.validUntil, sd.validAfter);
        }
        hash = ECDSA.toEthSignedMessageHash(hash);
        recovered = ECDSA.recover(hash, signature);
        sd = sessionData[recovered][msg.sender];
        if (sd.validUntil != 0) {
            return _packValidationData(false, sd.validUntil, sd.validAfter);
        }
        return VALIDATION_FAILED;
    }

    function isModuleType(
        uint256 moduleTypeId
    ) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function onInstall(bytes calldata data) external override {
        // Initialize
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
}
