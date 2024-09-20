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

import "forge-std/console2.sol";

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
    error CredibleAccountValidator_SessionKeyActive(address sessionKey);
    error CredibleAccountValidator_LockedTokensNotClaimed(address sessionKey);
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
        uint256 offset;
        address sessionKey = address(bytes20(_sessionData[offset:offset + 20]));
        offset += 20;
        if (sessionKey == address(0))
            revert CredibleAccountValidator_InvalidSessionKey();
        address solver = address(bytes20(_sessionData[offset:offset + 20]));
        offset += 20;
        bytes4 selector = bytes4(_sessionData[offset:offset + 4]);
        offset += 4;
        if (selector == bytes4(0))
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
        SessionData storage newSessionData = sessionData[sessionKey][
            msg.sender
        ];
        newSessionData.validAfter = validAfter;
        newSessionData.validUntil = validUntil;
        newSessionData.solver = solver;
        newSessionData.selector = selector;
        for (uint256 i; i < tokensLength; ++i) {
            address token = address(
                uint160(uint256(bytes32(_sessionData[offset:offset + 32])))
            );
            offset += 32;
            newSessionData.lockedTokens.push(
                LockedToken({token: token, lockedAmount: 0, claimedAmount: 0})
            );
        }
        uint256 amountsLength = uint256(
            bytes32(_sessionData[offset:offset + 32])
        );
        offset += 32;
        for (uint256 i; i < amountsLength; ++i) {
            uint256 amount = uint256(bytes32(_sessionData[offset:offset + 32]));
            offset += 32;
            newSessionData.lockedTokens[i].lockedAmount = amount;
        }
        walletSessionKeys[msg.sender].push(sessionKey);
        emit CredibleAccountValidator_SessionKeyEnabled(sessionKey, msg.sender);
    }

    // @inheritdoc ICredibleAccountValidator
    function disableSessionKey(address _session) public {
        if (sessionData[_session][msg.sender].validUntil == 0) {
            revert CredibleAccountValidator_SessionKeyDoesNotExist(_session);
        }

        if(sessionData[_session][msg.sender].validUntil > block.timestamp) {
            revert CredibleAccountValidator_SessionKeyActive(_session);
        }

        uint256 tokenCount = sessionData[_session][msg.sender].lockedTokens.length;
        for (uint256 i; i < tokenCount; ++i) {
            address tokenAddress = sessionData[_session][msg.sender].lockedTokens[i].token;
            (uint256 lockedAmount, uint256 claimedAmount) = 
            getTokenAmounts(_session, tokenAddress);
            if (lockedAmount != claimedAmount) {
                revert CredibleAccountValidator_LockedTokensNotClaimed(_session);
            }
        }

        delete sessionData[_session][msg.sender];
        walletSessionKeys[msg.sender] = ArrayLib._removeElement(
            getAssociatedSessionKeys(),
            _session
        );
        emit CredibleAccountValidator_SessionKeyDisabled(_session, msg.sender);
    }

    // @inheritdoc ICredibleAccountValidator
    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public returns (bool) {
        SessionData memory sd = sessionData[_sessionKey][msg.sender];
        if (isSessionClaimed(_sessionKey)) {
            return false;
        }
        bytes calldata callData = userOp.callData;
        if (bytes4(callData[:4]) == IERC7579Account.execute.selector) {
            ModeCode mode = ModeCode.wrap(bytes32(callData[4:36]));
            (CallType calltype, , , ) = ModeLib.decode(mode);
            if (calltype == CALLTYPE_SINGLE) {
                return
                    _validateSingleCall(
                        callData,
                        _sessionKey,
                        sd,
                        userOp.sender
                    );
            } else if (calltype == CALLTYPE_BATCH) {
                return
                    _validateBatchCall(
                        callData,
                        _sessionKey,
                        sd,
                        userOp.sender
                    );
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

    function getTokenAmounts(
        address _sessionKey,
        address _token
    ) public view returns (uint256, uint256) {
        SessionData memory sd = sessionData[_sessionKey][msg.sender];
        for (uint256 i; i < sd.lockedTokens.length; ++i) {
            if (sd.lockedTokens[i].token == _token) {
                return (
                    sd.lockedTokens[i].lockedAmount,
                    sd.lockedTokens[i].claimedAmount
                );
            }
        }
        return (0, 0);
    }

    function isSessionClaimed(address _sessionKey) public view returns (bool) {
        SessionData memory sd = sessionData[_sessionKey][msg.sender];
        for (uint256 i; i < sd.lockedTokens.length; ++i) {
            if (
                sd.lockedTokens[i].lockedAmount !=
                sd.lockedTokens[i].claimedAmount
            ) {
                return false;
            }
        }
        return true;
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
        (
            bytes memory signature,
            bytes32 merkleRoot,
            bytes32[] memory merkleProof
        ) = _digestSignature(userOp.signature);
        address sessionKeySigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(userOpHash),
            signature
        );
        if (!validateSessionKeyParams(sessionKeySigner, userOp)) {
            return VALIDATION_FAILED;
        }
        // Validate the Merkle proof (userOpHash is considered the leaf)
        // this is only stub method and to be replaced with actual Merkle proof validation logic
        if (!validateProof(merkleProof, merkleRoot, userOpHash)) {
            return VALIDATION_FAILED;
        }
        SessionData storage sd = sessionData[sessionKeySigner][msg.sender];
        // sd.claimed = true;
        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }

    // Stub method to validate Merkle proof
    function validateProof(
        bytes32[] memory _proof,
        bytes32 _root,
        bytes32 _leaf
    ) public pure returns (bool) {
        if (_proof.length == 0 || _root == bytes32(0)) {
            return false;
        }
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
            if ((sessionData[sessionKeys[i]][msg.sender].validUntil > block.timestamp) && !isSessionClaimed(sessionKeys[i])) {
                revert CredibleAccountValidator_LockedTokensNotClaimed(sessionKeys[i]);
            }
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

    /// @notice Validates a single call within a user operation against the session data
    /// @dev This function decodes the call data, extracts relevant information, and performs validation checks
    /// @param _callData The encoded call data from the user operation
    /// @param _sessionKey The session key
    /// @param _sd The session data
    /// @param _userOpSender The address of the account initiating the user operation
    /// @return bool Returns true if the call is valid according to the session data, false otherwise
    function _validateSingleCall(
        bytes calldata _callData,
        address _sessionKey,
        SessionData memory _sd,
        address _userOpSender
    ) internal returns (bool) {
        address target;
        bytes calldata execData;
        (target, , execData) = ExecutionLib.decodeSingle(_callData[100:]);

        (bytes4 selector, , address to, uint256 amount) = _digest(execData);

        if (selector != _sd.selector) return false;
        return
            _validateTokenData(
                _sessionKey,
                _sd.lockedTokens,
                selector,
                _userOpSender,
                to,
                amount,
                target
            );
    }

    /// @notice Validates a batch of calls within a user operation against the session data
    /// @dev This function decodes multiple executions, extracts relevant information, and performs validation checks for each
    /// @param _callData The encoded call data from the user operation containing multiple executions
    /// @param _sessionKey The session key
    /// @param _sd The session data
    /// @param _userOpSender The address of the account initiating the user operation
    /// @return bool Returns true if all calls in the batch are valid according to the session data, false otherwise
    function _validateBatchCall(
        bytes calldata _callData,
        address _sessionKey,
        SessionData memory _sd,
        address _userOpSender
    ) internal returns (bool) {
        Execution[] calldata execs = ExecutionLib.decodeBatch(_callData[100:]);
        for (uint256 i; i < execs.length; i++) {
            address target = execs[i].target;
            (bytes4 selector, , address to, uint256 amount) = _digest(
                execs[i].callData
            );
            if (selector != _sd.selector) return false;
            if (
                !_validateTokenData(
                    _sessionKey,
                    _sd.lockedTokens,
                    selector,
                    _userOpSender,
                    to,
                    amount,
                    target
                )
            ) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice check if the tokenAddress in calldata of userOp is part of the session data and wallet has sufficient token balance
     * @dev locked tokenBalance check is done in the CredibleAccountHook
     * @dev for `transfer` as function-selector, then check for the wallet balance
     * @dev for `transferFrom` as function-selector, then check for the wallet balance and allowance
     */
    function _validateTokenData(
        address _sessionKey,
        LockedToken[] memory _lockedTokens,
        bytes4 _selector,
        address _userOpSender,
        address _to,
        uint256 _amount,
        address _token
    ) internal returns (bool) {
        bool tokenFound;
        uint256 idx;
        for (uint256 i; i < _lockedTokens.length; ++i) {
            if (_lockedTokens[i].token == _token) {
                tokenFound = true;
                idx = i;
                break;
            }
        }
        if (!tokenFound) return false;

        if (_selector == IERC20.transfer.selector) {
            if (IERC20(_token).balanceOf(_userOpSender) < _amount) return false;
        } else if (_selector == IERC20.transferFrom.selector) {
            if (IERC20(_token).balanceOf(_userOpSender) < _amount) return false;
        }
        SessionData storage sd = sessionData[_sessionKey][_userOpSender];
        // incrementing the claimed amount for the token
        sd.lockedTokens[idx].claimedAmount += _amount;
        return true;
    }

    /// @notice Extracts and decodes relevant information from ERC20 function call data
    /// @dev Supports approve, transfer, and transferFrom functions of ERC20 tokens
    /// @param _data The calldata of the ERC20 function call
    /// @return selector The function selector (4 bytes)
    /// @return from The address tokens are transferred from (for transferFrom)
    /// @return to The address tokens are transferred to or approved for
    /// @return amount The amount of tokens involved in the transaction
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

    /// @notice Extracts signature components, merkle root, and merkle proof from the provided data
    /// @dev Decodes the signature, merkle root, and merkle proof from a single bytes array
    /// @param _signature The combined signature, merkle root, and merkle proof data
    /// @return signature The extracted signature (r, s, v)
    /// @return merkleRoot The extracted merkle root
    /// @return merkleProof The extracted merkle proof as an array of bytes32
    function _digestSignature(
        bytes calldata _signature
    )
        internal
        view
        returns (
            bytes memory signature,
            bytes32 merkleRoot,
            bytes32[] memory merkleProof
        )
    {
        bytes32 r = bytes32(_signature[0:32]);
        bytes32 s = bytes32(_signature[32:64]);
        uint8 v = uint8(_signature[64]);
        merkleRoot = bytes32(_signature[65:97]);

        signature = abi.encodePacked(r, s, v);

        // r (32 bytes) + s (32 bytes) + v (1 byte) + merkleRoot (32 bytes) = 97 bytes.
        uint256 proofLength = (_signature.length - 97) / 32;

        merkleProof = new bytes32[](proofLength);

        if (proofLength > 0) {
            uint256 proofStart = 97; // 32 byte r + 32 byte s + 1 byte v + 32 byte merkleRoot
            for (uint256 i; i < proofLength; ++i) {
                merkleProof[i] = bytes32(
                    _signature[proofStart + (i * 32):proofStart +
                        ((i + 1) * 32)]
                );
            }
        }

        return (signature, merkleRoot, merkleProof);
    }
}
