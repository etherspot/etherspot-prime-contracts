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

    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public view returns (bool valid) {
        bytes calldata callData = userOp.callData;
        bytes4 methodSig;
        assembly {
            let len := callData.length
            if gt(len, 3) {
                methodSig := calldataload(callData.offset)
            }
        }
        SessionData storage sd = sessionData[_sessionKey][msg.sender];
        if (sd.validUntil == 0 || sd.validUntil < block.timestamp)
            revert SSKV_InvalidSessionKey();
        console2.logBytes4(sd.funcSelector);
        if (methodSig != sd.funcSelector) revert SSKV_UnsupportedSelector();
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
        bytes calldata callData = userOp.callData;
        bytes4 methodSig;
        assembly {
            let len := callData.length
            if gt(len, 3) {
                methodSig := calldataload(callData.offset)
            }
        }
        console2.logBytes4(methodSig);
        // (address tokenAddr, uint256 callValue, ) = abi.decode(
        // userOp.callData[4:], // skip selector
        //     (address, uint256, bytes)
        // );
        // bytes calldata data;

        // {
        //     //offset represents where does the inner bytes array start
        //     uint256 offset = uint256(bytes32(userOp.callData[4 + 64:4 + 96]));
        //     uint256 length = uint256(
        //         bytes32(userOp.callData[4 + offset:4 + offset + 32])
        //     );
        //     //we expect data to be the `IERC20.transfer(address, uint256)` calldata
        //     data = userOp.callData[4 + offset + 32:4 + offset + 32 + length];
        // }
        // console2.logBytes(data);

        // (address recipientCalled, uint256 amount) = abi.decode(
        //     data[4:],
        //     (address, uint256)
        // );
        // console2.log("recipientCalled:", recipientCalled);
        // console2.log("amount:", amount);

        // console2.log("TokenAddress of UserOp:", tokenAddr);
        bytes32 hash = ECDSA.toEthSignedMessageHash(userOpHash);
        address recovered = ECDSA.recover(hash, userOp.signature);
        if (!validateSessionKeyParams(recovered, userOp))
            return VALIDATION_FAILED;
        SessionData storage sd = sessionData[recovered][msg.sender];
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
