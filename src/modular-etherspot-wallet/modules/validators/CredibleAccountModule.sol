// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {MODULE_TYPE_VALIDATOR, MODULE_TYPE_HOOK, VALIDATION_FAILED, VALIDATION_SUCCESS} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import {ICredibleAccountModule} from "../../interfaces/ICredibleAccountModule.sol";
import {IProofVerifier} from "../../interfaces/IProofVerifier.sol";
import {IHookLens} from "../../interfaces/IHookLens.sol";
import {IHookMultiPlexer} from "../hooks/multiplexer/interfaces/IHookMultiPlexer.sol";
import {HookType} from "../hooks/multiplexer/DataTypes.sol";
import {SessionData, TokenData} from "../../common/Structs.sol";

contract CredibleAccountModule is ICredibleAccountModule {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error CredibleAccountModule_ModuleAlreadyInstalled();
    error CredibleAccountModule_ModuleNotInstalled();
    error CredibleAccountModule_InvalidSessionKey();
    error CredibleAccountModule_InvalidProofVerifier();
    error CredibleAccountModule_InvalidValidAfter();
    error CredibleAccountModule_InvalidValidUntil(uint48 validUntil);
    error CredibleAccountModule_SessionKeyDoesNotExist(address session);
    error CredibleAccountModule_LockedTokensNotClaimed(address sessionKey);
    error CredibleAccountModule_InvalidHookMultiPlexer();
    error CredibleAccountModule_HookMultiplexerIsNotInstalled();
    error CredibleAccountModule_NotAddedToHookMultiplexer();
    error CredibleAccountModule_InvalidOnInstallData(address wallet);
    error CredibleAccountModule_InvalidOnUnInstallData(address wallet);
    error CredibleAccountModule_InvalidModuleType();
    error CredibleAccountModule_ValidatorExists();
    error NotImplemented();
    error CredibleAccountModule_InsufficientUnlockedBalance(address token);

    /*//////////////////////////////////////////////////////////////
                               MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(address wallet => Initialization) public moduleInitialized;
    mapping(address wallet => address[] keys) public walletSessionKeys;
    mapping(address sessionKey => mapping(address wallet => SessionData))
        public sessionData;
    mapping(address sessionKey => LockedToken[]) public lockedTokens;

    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

    IProofVerifier public immutable proofVerifier;
    IHookMultiPlexer public immutable hookMultiPlexer;
    uint256 constant EXEC_OFFSET = 100;

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _proofVerifier, address _hookMultiPlexer) {
        if (_proofVerifier == address(0))
            revert CredibleAccountModule_InvalidProofVerifier();
        if (_hookMultiPlexer == address(0))
            revert CredibleAccountModule_InvalidHookMultiPlexer();
        hookMultiPlexer = IHookMultiPlexer(_hookMultiPlexer);
        proofVerifier = IProofVerifier(_proofVerifier);
    }

    /*//////////////////////////////////////////////////////////////
                      VALIDATOR PUBLIC/EXTERNAL
    //////////////////////////////////////////////////////////////*/

    // @inheritdoc ICredibleAccountModule
    function enableSessionKey(bytes calldata _sessionData) external {
        (
            address sessionKey,
            uint48 validAfter,
            uint48 validUntil,
            TokenData[] memory tokenAmounts
        ) = abi.decode(_sessionData, (address, uint48, uint48, TokenData[]));
        if (sessionKey == address(0))
            revert CredibleAccountModule_InvalidSessionKey();
        if (validAfter == 0) revert CredibleAccountModule_InvalidValidAfter();
        if (validUntil == 0 || validUntil <= validAfter)
            revert CredibleAccountModule_InvalidValidUntil(validUntil);
        sessionData[sessionKey][msg.sender] = SessionData({
            sessionKey: sessionKey,
            validAfter: validAfter,
            validUntil: validUntil,
            live: true // unused
        });
        for (uint256 i; i < tokenAmounts.length; ++i) {
            lockedTokens[sessionKey].push(
                LockedToken({
                    token: tokenAmounts[i].token,
                    lockedAmount: tokenAmounts[i].amount,
                    claimedAmount: 0
                })
            );
        }
        walletSessionKeys[msg.sender].push(sessionKey);
        emit CredibleAccountModule_SessionKeyEnabled(sessionKey, msg.sender);
    }

    // @inheritdoc ICredibleAccountModule
    function disableSessionKey(address _sessionKey) external {
        if (sessionData[_sessionKey][msg.sender].validUntil == 0)
            revert CredibleAccountModule_SessionKeyDoesNotExist(_sessionKey);
        if (
            sessionData[_sessionKey][msg.sender].validUntil >=
            block.timestamp &&
            !isSessionClaimed(_sessionKey)
        ) revert CredibleAccountModule_LockedTokensNotClaimed(_sessionKey);
        delete sessionData[_sessionKey][msg.sender];
        delete lockedTokens[_sessionKey];
        address[] storage keys = walletSessionKeys[msg.sender];
        for (uint256 i; i < keys.length; ++i) {
            if (keys[i] == _sessionKey) {
                keys[i] = keys[keys.length - 1];
                keys.pop();
                break;
            }
        }
        emit CredibleAccountModule_SessionKeyDisabled(_sessionKey, msg.sender);
    }

    // @inheritdoc ICredibleAccountModule
    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public returns (bool) {
        if (isSessionClaimed(_sessionKey)) return false;
        bytes calldata callData = userOp.callData;
        if (bytes4(callData[:4]) == IERC7579Account.execute.selector) {
            ModeCode mode = ModeCode.wrap(bytes32(callData[4:36]));
            (CallType calltype, , , ) = ModeLib.decode(mode);
            if (calltype == CALLTYPE_SINGLE) {
                return
                    _validateSingleCall(callData, _sessionKey, userOp.sender);
            } else if (calltype == CALLTYPE_BATCH) {
                return _validateBatchCall(callData, _sessionKey, userOp.sender);
            }
        }
        return false;
    }

    // @inheritdoc ICredibleAccountModule
    function getSessionKeysByWallet() public view returns (address[] memory) {
        return walletSessionKeys[msg.sender];
    }

    // @inheritdoc ICredibleAccountModule
    function getSessionKeysByWallet(
        address _wallet
    ) public view returns (address[] memory) {
        return walletSessionKeys[_wallet];
    }

    // @inheritdoc ICredibleAccountModule
    function getSessionKeyData(
        address _sessionKey
    ) external view returns (SessionData memory) {
        return sessionData[_sessionKey][msg.sender];
    }

    // @inheritdoc ICredibleAccountModule
    function getLockedTokensForSessionKey(
        address _sessionKey
    ) external view returns (LockedToken[] memory) {
        return lockedTokens[_sessionKey];
    }

    // @inheritdoc ICredibleAccountModule
    function tokenTotalLockedForWallet(
        address _token
    ) external view returns (uint256) {
        return _retrieveLockedBalance(msg.sender, _token);
    }

    // @inheritdoc ICredibleAccountModule
    function cumulativeLockedForWallet()
        external
        view
        returns (TokenData[] memory)
    {
        return _cumulativeLockedForWallet(msg.sender);
    }

    // @inheritdoc ICredibleAccountModule
    function isSessionClaimed(address _sessionKey) public view returns (bool) {
        LockedToken[] memory tokens = lockedTokens[_sessionKey];
        for (uint256 i; i < tokens.length; ++i) {
            if (tokens[i].lockedAmount != tokens[i].claimedAmount) return false;
        }
        return true;
    }

    // @inheritdoc ICredibleAccountModule
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256) {
        if (userOp.signature.length < 65) {
            return VALIDATION_FAILED;
        }
        (bytes memory sig, bytes memory proof) = _digestSignature(
            userOp.signature
        );
        address sessionKeySigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(userOpHash),
            sig
        );
        // Validate the proof & session key params
        // this is only stub method and to be replaced with actual proof validation logic
        if (
            !validateSessionKeyParams(sessionKeySigner, userOp) ||
            !proofVerifier.verifyProof(proof)
        ) return VALIDATION_FAILED;
        SessionData memory sd = sessionData[sessionKeySigner][msg.sender];
        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }

    // @inheritdoc ICredibleAccountModule
    function isModuleType(
        uint256 moduleTypeId
    ) external pure override returns (bool) {
        return
            moduleTypeId == MODULE_TYPE_VALIDATOR ||
            moduleTypeId == MODULE_TYPE_HOOK;
    }

    // @inheritdoc ICredibleAccountModule
    function onInstall(bytes calldata data) external override {
        if (data.length < 32)
            revert CredibleAccountModule_InvalidOnInstallData(msg.sender);
        uint256 moduleType;
        assembly {
            moduleType := calldataload(data.offset)
        }
        if (moduleType == MODULE_TYPE_VALIDATOR) {
            if (
                IHookLens(msg.sender).getActiveHook() !=
                address(hookMultiPlexer)
            ) revert CredibleAccountModule_HookMultiplexerIsNotInstalled();
            if (
                !hookMultiPlexer.hasHook(
                    msg.sender,
                    address(this),
                    HookType.GLOBAL
                )
            ) revert CredibleAccountModule_NotAddedToHookMultiplexer();
            moduleInitialized[msg.sender].validatorInitialized = true;
            emit CredibleAccountModule_ModuleInstalled(msg.sender);
        } else if (moduleType == MODULE_TYPE_HOOK) {
            moduleInitialized[msg.sender].hookInitialized = true;
        } else {
            revert CredibleAccountModule_InvalidModuleType();
        }
    }

    // @inheritdoc ICredibleAccountModule
    function onUninstall(bytes calldata data) external override {
        if (data.length < 32)
            revert CredibleAccountModule_InvalidOnUnInstallData(msg.sender);
        uint256 moduleType;
        address sender;
        assembly {
            moduleType := calldataload(data.offset)
            sender := calldataload(add(data.offset, 32))
        }
        bytes memory uninstallData = data[32:];
        if (moduleType == MODULE_TYPE_VALIDATOR) {
            if (IHookLens(sender).getActiveHook() != address(hookMultiPlexer))
                revert CredibleAccountModule_HookMultiplexerIsNotInstalled();
            if (
                !hookMultiPlexer.hasHook(sender, address(this), HookType.GLOBAL)
            ) revert CredibleAccountModule_NotAddedToHookMultiplexer();
            address[] memory sessionKeys = getSessionKeysByWallet();
            for (uint256 i; i < sessionKeys.length; i++) {
                if (
                    (sessionData[sessionKeys[i]][sender].validUntil >
                        block.timestamp) && !isSessionClaimed(sessionKeys[i])
                )
                    revert CredibleAccountModule_LockedTokensNotClaimed(
                        sessionKeys[i]
                    );
                delete sessionData[sessionKeys[i]][sender];
                delete lockedTokens[sessionKeys[i]];
            }
            delete walletSessionKeys[sender];
            moduleInitialized[sender].validatorInitialized = false;
            emit CredibleAccountModule_ModuleUninstalled(sender);
        } else if (moduleType == MODULE_TYPE_HOOK) {
            if (moduleInitialized[sender].validatorInitialized == true)
                revert CredibleAccountModule_ValidatorExists();
            moduleInitialized[sender].hookInitialized = false;
        } else {
            revert CredibleAccountModule_InvalidModuleType();
        }
    }

    // @inheritdoc ICredibleAccountModule
    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4) {
        revert NotImplemented();
    }

    // @inheritdoc ICredibleAccountModule
    function isInitialized(address smartAccount) external view returns (bool) {
        return moduleInitialized[smartAccount].validatorInitialized;
    }

    /*//////////////////////////////////////////////////////////////
                          VALIDATOR INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates a single call within a user operation against the session data
    /// @dev This function decodes the call data, extracts relevant information, and performs validation checks
    /// @param _callData The encoded call data from the user operation
    /// @param _sessionKey The session key
    /// @param _wallet The address of the account initiating the user operation
    /// @return bool Returns true if the call is valid according to the session data, false otherwise
    function _validateSingleCall(
        bytes calldata _callData,
        address _sessionKey,
        address _wallet
    ) internal returns (bool) {
        (address target, , bytes calldata execData) = ExecutionLib.decodeSingle(
            _callData[EXEC_OFFSET:]
        );
        (bytes4 selector, , , uint256 amount) = _digestClaimTx(execData);
        if (!_isValidSelector(selector)) return false;
        return _validateTokenData(_sessionKey, _wallet, amount, target);
    }

    /// @notice Validates a batch of calls within a user operation against the session data
    /// @dev This function decodes multiple executions, extracts relevant information, and performs validation checks for each
    /// @param _callData The encoded call data from the user operation containing multiple executions
    /// @param _sessionKey The session key
    /// @param _wallet The address of the account initiating the user operation
    /// @return bool Returns true if all calls in the batch are valid according to the session data, false otherwise
    function _validateBatchCall(
        bytes calldata _callData,
        address _sessionKey,
        address _wallet
    ) internal returns (bool) {
        Execution[] calldata execs = ExecutionLib.decodeBatch(
            _callData[EXEC_OFFSET:]
        );
        for (uint256 i; i < execs.length; ++i) {
            (bytes4 selector, , , uint256 amount) = _digestClaimTx(
                execs[i].callData
            );
            if (
                !_isValidSelector(selector) ||
                !_validateTokenData(
                    _sessionKey,
                    _wallet,
                    amount,
                    execs[i].target
                )
            ) return false;
        }
        return true;
    }
    /**
     * @notice check if the tokenAddress in calldata of userOp is part of the session data and wallet has sufficient token balance
     * @dev locked tokenBalance check is done in the CredibleAccountModule
     * @dev for `transfer` as function-selector, then check for the wallet balance
     * @dev for `transferFrom` as function-selector, then check for the wallet balance and allowance
     */
    function _validateTokenData(
        address _sessionKey,
        address _wallet,
        uint256 _amount,
        address _token
    ) internal returns (bool) {
        LockedToken[] storage tokens = lockedTokens[_sessionKey];
        for (uint256 i; i < tokens.length; ++i) {
            if (tokens[i].token == _token) {
                if (
                    _walletTokenBalance(_wallet, _token) >= _amount &&
                    _amount == tokens[i].lockedAmount
                ) {
                    tokens[i].claimedAmount += _amount;
                    return true;
                }
            }
        }
        return false;
    }

    /// @notice Extracts and decodes relevant information from ERC20 function call data
    /// @dev Supports transferFrom function of ERC20 tokens
    /// @param _data The calldata of the ERC20 function call
    /// @return The function selector (4 bytes)
    /// @return The address tokens are transferred from (for transferFrom)
    /// @return The address tokens are transferred to or approved for
    /// @return The amount of tokens involved in the transaction
    function _digestClaimTx(
        bytes calldata _data
    ) internal pure returns (bytes4, address, address, uint256) {
        bytes4 selector = bytes4(_data[0:4]);
        if (!_isValidSelector(selector))
            return (bytes4(0), address(0), address(0), 0);
        address from = address(bytes20(_data[16:36]));
        address to = address(bytes20(_data[48:68]));
        uint256 amount = uint256(bytes32(_data[68:100]));
        return (selector, from, to, amount);
    }

    /// @notice Extracts signature components and proof from the provided data
    /// @dev Decodes the signature, and proof from a single bytes array
    /// @param _signature The combined signature, proof data
    /// @return The extracted signature (r, s, v)
    /// @return The proof
    function _digestSignature(
        bytes calldata _signature
    ) internal pure returns (bytes memory, bytes memory) {
        bytes32 r = bytes32(_signature[0:32]);
        bytes32 s = bytes32(_signature[32:64]);
        uint8 v = uint8(_signature[64]);
        bytes memory proof = bytes(_signature[65:]);
        bytes memory signature = abi.encodePacked(r, s, v);
        // r (32 bytes) + s (32 bytes) + v (1 byte) = 65 bytes.
        // uint256 proofLength = _signature.length - 65;
        // proof = new bytes(proofLength);
        // if (proofLength > 0) {
        //     uint256 proofStart = 65; // 32 byte r + 32 byte s + 1 byte v
        //     for (uint256 i; i < proofLength; ++i) {
        //         proof[i] = _signature[proofStart + i];
        //     }
        // }
        return (signature, proof);
    }

    /*//////////////////////////////////////////////////////////////
                         HOOK PUBLIC/EXTERNAL
    //////////////////////////////////////////////////////////////*/

    // @inheritdoc ICredibleAccountModule
    function preCheck(
        address msgSender,
        uint256 msgValue,
        bytes calldata msgData
    ) external override returns (bytes memory hookData) {
        (address sender, ) = abi.decode(msgData, (address, bytes));
        return abi.encode(sender, _cumulativeLockedForWallet(sender));
    }

    // @inheritdoc ICredibleAccountModule
    function postCheck(bytes calldata hookData) external {
        if (hookData.length == 0) return;
        (address sender, TokenData[] memory preCheckBalances) = abi.decode(
            hookData,
            (address, TokenData[])
        );
        for (uint256 i; i < preCheckBalances.length; ) {
            address token = preCheckBalances[i].token;
            uint256 preCheckLocked = preCheckBalances[i].amount;
            uint256 walletBalance = _walletTokenBalance(sender, token);
            uint256 postCheckLocked = _retrieveLockedBalance(sender, token);
            if (
                walletBalance < preCheckLocked &&
                walletBalance < postCheckLocked
            ) {
                revert CredibleAccountModule_InsufficientUnlockedBalance(token);
            }
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            HOOK INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the total locked balance for a specific token across all session keys
    /// @dev Iterates through all session keys and their locked tokens to calculate the total locked balance
    /// @param _wallet The address of the wallet to check the locked balance for
    /// @param _token The address of the token to check the locked balance for
    /// @return The total locked balance of the specified token across all session keys
    function _retrieveLockedBalance(
        address _wallet,
        address _token
    ) internal view returns (uint256) {
        address[] memory sessionKeys = getSessionKeysByWallet(_wallet);
        uint256 totalLocked;
        uint256 sessionKeysLength = sessionKeys.length;
        for (uint256 i; i < sessionKeysLength; ) {
            LockedToken[] memory tokens = lockedTokens[sessionKeys[i]];
            uint256 tokensLength = tokens.length;
            for (uint256 j; j < tokensLength; ) {
                LockedToken memory lockedToken = tokens[j];
                if (lockedToken.token == _token) {
                    totalLocked += (lockedToken.lockedAmount -
                        lockedToken.claimedAmount);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return totalLocked;
    }

    /// @notice Gets the cumulative locked state of all tokens across all session keys
    /// @dev Aggregates locked token balances for all session keys, combining balances for the same token
    /// @return Array of TokenData structures representing the initial locked state
    function _cumulativeLockedForWallet(
        address _wallet
    ) internal view returns (TokenData[] memory) {
        address[] memory sessionKeys = getSessionKeysByWallet(_wallet);
        TokenData[] memory tokenData = new TokenData[](0);
        uint256 unique;
        for (uint256 i; i < sessionKeys.length; ++i) {
            LockedToken[] memory locks = lockedTokens[sessionKeys[i]];
            for (uint256 j; j < locks.length; ++j) {
                address token = locks[j].token;
                bool found = false;
                for (uint256 k; k < unique; ++k) {
                    if (tokenData[k].token == token) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    TokenData[] memory newTokenData = new TokenData[](
                        unique + 1
                    );
                    for (uint256 m; m < unique; ++m)
                        newTokenData[m] = tokenData[m];
                    uint256 totalLocked = _retrieveLockedBalance(
                        _wallet,
                        token
                    );
                    newTokenData[unique] = TokenData(token, totalLocked);
                    tokenData = newTokenData;
                    unique++;
                }
            }
        }
        return tokenData;
    }

    function _walletTokenBalance(
        address _wallet,
        address _token
    ) internal view returns (uint256) {
        return IERC20(_token).balanceOf(_wallet);
    }

    function _isValidSelector(bytes4 _selector) internal pure returns (bool) {
        return _selector == IERC20.transfer.selector;
    }
}
