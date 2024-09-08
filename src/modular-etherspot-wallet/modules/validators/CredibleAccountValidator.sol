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
import {ICredibleAccountValidator} from "../../interfaces/ICredibleAccountValidator.sol";
import {ArrayLib} from "../../libraries/ArrayLib.sol";

contract CredibleAccountValidator is ICredibleAccountValidator {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    string constant NAME = "CredibleAccountValidator";
    string constant VERSION = "1.0.0";

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error CredibleAccountValidator_ModuleAlreadyInstalled();
    error CredibleAccountValidator_ModuleNotInstalled();
    error CredibleAccountValidator_InvalidSessionKey();
    error CredibleAccountValidator_InvalidToken();
    error CredibleAccountValidator_InvalidFunctionSelector();
    error CredibleAccountValidator_InvalidSpendingLimit();
    error CredibleAccountValidator_InvalidValidAfter(uint48 validAfter);
    error CredibleAccountValidator_InvalidValidUntil(uint48 validUntil);
    error CredibleAccountValidator_InvalidTokenAmountData(address sessionKey);
    error CredibleAccountValidator_SessionKeyAlreadyExists(address sessionKey);
    error CredibleAccountValidator_SessionKeyDoesNotExist(address session);
    error CredibleAccountValidator_SessionPaused(address sessionKey);
    error NotImplemented();

    /*//////////////////////////////////////////////////////////////
                               MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public initialized;
    mapping(address wallet => address[] assocSessionKeys)
        public walletSessionKeys;
    mapping(address sessionKey => mapping(address wallet => SessionData))
        public sessionData;

    /*//////////////////////////////////////////////////////////////
                           PUBLIC/EXTERNAL
    //////////////////////////////////////////////////////////////*/

    // @inheritdoc ICredibleAccountValidator
    function enableSessionKey(bytes calldata _sessionData) public {
        uint256 offset = 0;

        address sessionKey = address(bytes20(_sessionData[offset:offset + 20]));
        offset += 20;
        if (sessionKey == address(0))
            revert CredibleAccountValidator_InvalidSessionKey();

        address solverAddress = address(
            bytes20(_sessionData[offset:offset + 20])
        );
        offset += 20;

        bytes4 funcSelector = bytes4(_sessionData[offset:offset + 4]);
        offset += 4;
        if (funcSelector == bytes4(0))
            revert CredibleAccountValidator_InvalidFunctionSelector();

        uint48 validAfter = uint48(bytes6(_sessionData[offset:offset + 6]));
        offset += 6;
        if (validAfter == 0)
            revert CredibleAccountValidator_InvalidValidAfter(validAfter);

        uint48 validUntil = uint48(bytes6(_sessionData[offset:offset + 6]));
        offset += 6;
        if (validUntil == 0)
            revert CredibleAccountValidator_InvalidValidUntil(validUntil);

        uint256 tokensLength = uint256(
            bytes32(_sessionData[offset:offset + 32])
        );
        offset += 32;

        address[] memory tokens = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            tokens[i] = address(
                uint160(uint256(bytes32(_sessionData[offset:offset + 32])))
            );
            offset += 32;
        }

        uint256 amountsLength = uint256(
            bytes32(_sessionData[offset:offset + 32])
        );
        offset += 32;

        // Decode amounts array
        uint256[] memory amounts = new uint256[](amountsLength);
        for (uint256 i = 0; i < amountsLength; i++) {
            amounts[i] = uint256(bytes32(_sessionData[offset:offset + 32]));
            offset += 32;
        }

        if (tokensLength != amountsLength)
            revert CredibleAccountValidator_InvalidTokenAmountData(sessionKey);

        // Store the decoded data in sessionData mapping
        sessionData[sessionKey][msg.sender] = SessionData(
            tokens,
            funcSelector,
            amounts,
            solverAddress,
            validAfter,
            validUntil,
            true
        );

        walletSessionKeys[msg.sender].push(sessionKey);
        emit CredibleAccountValidator_SessionKeyEnabled(sessionKey, msg.sender);
    }

    // @inheritdoc ICredibleAccountValidator
    function disableSessionKey(address _session) public {
        if (sessionData[_session][msg.sender].validUntil == 0)
            revert CredibleAccountValidator_SessionKeyDoesNotExist(_session);
        delete sessionData[_session][msg.sender];
        walletSessionKeys[msg.sender] = ArrayLib._removeElement(
            getAssociatedSessionKeys(),
            _session
        );
        emit CredibleAccountValidator_SessionKeyDisabled(_session, msg.sender);
    }

    // @inheritdoc ICredibleAccountValidator
    function rotateSessionKey(
        address _oldSessionKey,
        bytes calldata _newSessionData
    ) external {
        disableSessionKey(_oldSessionKey);
        enableSessionKey(_newSessionData);
    }

    // @inheritdoc ICredibleAccountValidator
    function toggleSessionKeyPause(address _sessionKey) external {
        SessionData storage sd = sessionData[_sessionKey][msg.sender];
        if (sd.validUntil == 0)
            revert CredibleAccountValidator_SessionKeyDoesNotExist(_sessionKey);
        if (sd.live) {
            sd.live = false;
            emit CredibleAccountValidator_SessionKeyPaused(
                _sessionKey,
                msg.sender
            );
        } else {
            sd.live = true;
            emit CredibleAccountValidator_SessionKeyUnpaused(
                _sessionKey,
                msg.sender
            );
        }
    }

    // @inheritdoc ICredibleAccountValidator
    function isSessionKeyLive(address _sessionKey) public view returns (bool) {
        return sessionData[_sessionKey][msg.sender].live;
    }

    // @inheritdoc ICredibleAccountValidator
    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public view returns (bool) {
        SessionData memory sd = sessionData[_sessionKey][msg.sender];
        if (!isSessionKeyLive(_sessionKey)) {
            return false;
        }

        bytes calldata callData = userOp.callData;
        if (bytes4(callData[:4]) == IERC7579Account.execute.selector) {
            ModeCode mode = ModeCode.wrap(bytes32(callData[4:36]));
            (CallType calltype, , , ) = ModeLib.decode(mode);

            if (calltype == CALLTYPE_SINGLE) {
                return _validateSingleCall(callData, sd, userOp.sender);
            } else if (calltype == CALLTYPE_BATCH) {
                return _validateBatchCall(callData, sd, userOp.sender);
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    // @inheritdoc ICredibleAccountValidator
    function getAssociatedSessionKeys() public view returns (address[] memory) {
        return walletSessionKeys[msg.sender];
    }

    // @inheritdoc ICredibleAccountValidator
    function getSessionKeyData(
        address _sessionKey
    ) public view returns (SessionData memory) {
        return sessionData[_sessionKey][msg.sender];
    }

    /**
     * @notice Validates a user operation.
     * @dev This function checks the length of the signature and extracts the necessary components.
     *      The signature must be at least 129 bytes long to include the following:
     *      - 32 bytes for `r`
     *      - 32 bytes for `s`
     *      - 1 byte for `v`
     *      - 32 bytes for `merkleRoot`
     *      - 32 bytes for at least one entry in the `merkleProof`
     * @param userOp The packed user operation containing the signature and other data.
     * @param userOpHash The hash of the user operation.
     * @return A status code indicating the result of the validation.
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256) {
        if (userOp.signature.length < 129) {
            return VALIDATION_FAILED;
        }
   
        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes32 merkleRoot;
        bytes memory signature = userOp.signature;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
            merkleRoot := mload(add(signature, 0x80))
        }

        bytes memory rebuiltSignature = abi.encodePacked(r, s, v);

        address sessionKeySigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(userOpHash),
            rebuiltSignature
        );

        if (!validateSessionKeyParams(sessionKeySigner, userOp)) {
            return VALIDATION_FAILED;
        }

        // Calculate the length of the Merkle proof
        // r (32 bytes) + s (32 bytes) + v (1 byte) + merkleRoot (32 bytes) = 97 bytes.
        uint256 proofLength = (signature.length - 97) / 32;

        if(proofLength == 0) {
           return VALIDATION_FAILED;
        }

        bytes32[] memory merkleProof = new bytes32[](proofLength);

        assembly {
            // 160 byte offset (32 byte r, 32 byte s, 1 byte v, 32 byte merkleRoot)
            let proofStart := add(signature, 0x61) 
            for { let i := 0 } lt(i, proofLength) { i := add(i, 1) } {
                mstore(add(merkleProof, add(0x20, mul(i, 0x20))), mload(add(proofStart, mul(i, 0x20))))
            }
        }

        // Validate the Merkle proof (userOpHash is considered the leaf)
        // this is only stub method and to be replaced with actual Merkle proof validation logic
        if (!validateProof(merkleProof, merkleRoot, userOpHash)) {
            return VALIDATION_FAILED;
        }

        SessionData memory sd = sessionData[sessionKeySigner][msg.sender];

        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }

    // Stub method to validate Merkle proof
    function validateProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        // Placeholder for actual Merkle proof validation logic
        return true;
    }

    // @inheritdoc ICredibleAccountValidator
    function isModuleType(
        uint256 moduleTypeId
    ) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    // @inheritdoc ICredibleAccountValidator
    function onInstall(bytes calldata data) external override {
        if (initialized[msg.sender] == true)
            revert CredibleAccountValidator_ModuleAlreadyInstalled();
        initialized[msg.sender] = true;
        emit CredibleAccountValidator_ModuleInstalled(msg.sender);
    }

    // @inheritdoc ICredibleAccountValidator
    function onUninstall(bytes calldata data) external override {
        if (initialized[msg.sender] == false)
            revert CredibleAccountValidator_ModuleNotInstalled();
        address[] memory sessionKeys = getAssociatedSessionKeys();
        uint256 sessionKeysLength = sessionKeys.length;
        for (uint256 i; i < sessionKeysLength; i++) {
            delete sessionData[sessionKeys[i]][msg.sender];
        }
        delete walletSessionKeys[msg.sender];
        initialized[msg.sender] = false;
        emit CredibleAccountValidator_ModuleUninstalled(msg.sender);
    }

    // @inheritdoc ICredibleAccountValidator
    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4) {
        revert NotImplemented();
    }

    // @inheritdoc ICredibleAccountValidator
    function isInitialized(address smartAccount) external view returns (bool) {
        return initialized[smartAccount];
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _validateSingleCall(
        bytes calldata callData,
        SessionData memory sd,
        address userOpSender
    ) internal view returns (bool) {
        address target;
        bytes calldata execData;
        (target, , execData) = ExecutionLib.decodeSingle(callData[100:]);

        (bytes4 selector, address from, , uint256 amount) = _digest(execData);

        if (selector != sd.funcSelector) return false;
        return
            _validateTokenData(
                sd.tokens,
                selector,
                userOpSender,
                from,
                amount,
                target
            );
    }

    // Internal function to validate batch call
    function _validateBatchCall(
        bytes calldata callData,
        SessionData memory sd,
        address userOpSender
    ) internal view returns (bool) {
        Execution[] calldata execs = ExecutionLib.decodeBatch(callData[100:]);
        for (uint256 i; i < execs.length; i++) {
            address target = execs[i].target;
            (bytes4 selector, address from, , uint256 amount) = _digest(
                execs[i].callData
            );
            if (selector != sd.funcSelector) return false;
            if (
                !_validateTokenData(
                    sd.tokens,
                    selector,
                    userOpSender,
                    from,
                    amount,
                    target
                )
            ) {
                return false;
            }
        }
        return true;
    }

    function _validateTokenData(
        address[] memory tokens,
        bytes4 selector,
        address userOpSender,
        address from,
        uint256 amount,
        address token
    ) internal view returns (bool) {
        (bool tokenFound, ) = _findTokenIndex(tokens, token);

        if (!tokenFound) return false;

        // Validate if wallet has sufficient balance
        if (selector == IERC20.transfer.selector) {
            if (IERC20(token).balanceOf(userOpSender) < amount) {
                return false;
            }
        } else if (selector == IERC20.transferFrom.selector) {
            if (
                IERC20(token).balanceOf(userOpSender) < amount ||
                IERC20(token).allowance(userOpSender, from) < amount
            ) {
                return false;
            }
        }

        return true;
    }

    function _findTokenIndex(
        address[] memory tokens,
        address target
    ) internal pure returns (bool, uint256) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == target) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function _digest(
        bytes calldata _data
    )
        internal
        pure
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
