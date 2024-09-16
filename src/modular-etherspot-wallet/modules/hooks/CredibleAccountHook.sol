// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import {MODULE_TYPE_HOOK} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICredibleAccountHook} from "../../interfaces/ICredibleAccountHook.sol";
import {CredibleAccountValidator as CAV} from "../validators/CredibleAccountValidator.sol";
import {MODE_SELECTOR_CREDIBLE_ACCOUNT} from "../../common/Constants.sol";

contract CredibleAccountHook is ICredibleAccountHook {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /*//////////////////////////////////////////////////////////////
                               MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public installed;
    mapping(address => LockedToken[]) public lockedTokens;
    mapping(address => uint256) public transactionsInProgress;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error CredibleAccountHook_TokenIsNotLocked(
        address sessionKey,
        address token
    );
    error CredibleAccountHook_CantUninstallWhileTransactionInProgress(
        address wallet
    );
    error CredibleAccountHook_TransactionInProgress(
        address wallet,
        address token
    );
    error CredibleAccountHook_InvalidCallType(CallType callType);
    error CredibleAccountHook_UnsuccessfulUnlock();
    error CredibleAccountHook_UnsuccessfulLock();
    error CredibleAccountHook_InsufficientUnlockedBalance(address token);
    error CredibleAccountHook_CannotEnableSessionKeyWithoutModeSelector();
    error CredibleAccountHook_SessionKeyAlreadyExists(
        address wallet,
        address sessionKey
    );

    /*//////////////////////////////////////////////////////////////
                           PUBLIC/EXTERNAL
    //////////////////////////////////////////////////////////////*/

    //@inheritdoc ICredibleAccountHook
    function isTokenLocked(
        address wallet,
        address _token
    ) public view returns (bool) {
        LockedToken[] storage tokens = lockedTokens[wallet];
        for (uint256 i; i < tokens.length; ++i) {
            if (tokens[i].token == _token && tokens[i].amount > 0) {
                return true;
            }
        }
        return false;
    }

    //@inheritdoc ICredibleAccountHook
    function retrieveLockedBalance(
        address _token
    ) public view returns (uint256) {
        uint256 totalLocked;
        LockedToken[] storage locks = lockedTokens[msg.sender];
        for (uint256 i; i < locks.length; ++i) {
            if (locks[i].token == _token) {
                totalLocked += locks[i].amount;
            }
        }
        return totalLocked;
    }

    //@inheritdoc ICredibleAccountHook
    function isTransactionInProgress(
        address _wallet
    ) public view returns (bool) {
        return transactionsInProgress[_wallet] > 0;
    }

    //@inheritdoc ICredibleAccountHook
    function preCheck(
        address msgSender,
        uint256 msgValue,
        bytes calldata msgData
    ) external override returns (bytes memory hookData) {
        ModeCode mode = ModeCode.wrap(bytes32(msgData[4:36]));
        (
            CallType callType,
            ,
            ModeSelector modeSelector,
            ModePayload modePayload
        ) = mode.decode();
        _checkPermittedCredibleAccountAction(
            callType,
            modeSelector,
            modePayload,
            msgData[100:]
        );
        return _encodeInitialLockedState();
    }

    //@inheritdoc ICredibleAccountHook
    function postCheck(bytes calldata hookData) external {
        if (hookData.length != 0) {
            TokenBalance[] memory initialBalances = abi.decode(
                hookData,
                (TokenBalance[])
            );
            for (uint256 i; i < initialBalances.length; ++i) {
                address token = initialBalances[i].token;
                uint256 initialBalance = initialBalances[i].balance;
                uint256 currentBalance = IERC20(token).balanceOf(msg.sender);
                uint256 lockedAmount = retrieveLockedBalance(token);
                if (currentBalance < initialBalance) {
                    if (currentBalance < lockedAmount)
                        revert CredibleAccountHook_InsufficientUnlockedBalance(
                            token
                        );
                }
            }
        }
    }
    //@inheritdoc ICredibleAccountHook
    function onInstall(bytes calldata data) external override {
        installed[msg.sender] = true;
        emit CredibleAccountHook_ModuleInstalled(msg.sender);
    }

    //@inheritdoc ICredibleAccountHook
    function onUninstall(bytes calldata data) external override {
        if (transactionsInProgress[msg.sender] > 0)
            revert CredibleAccountHook_CantUninstallWhileTransactionInProgress(
                msg.sender
            );
        installed[msg.sender] = false;
        delete lockedTokens[msg.sender];
        delete transactionsInProgress[msg.sender];
        emit CredibleAccountHook_ModuleUninstalled(msg.sender);
    }

    //@inheritdoc ICredibleAccountHook
    function isInitialized(
        address smartAccount
    ) external view override returns (bool) {
        return installed[smartAccount];
    }

    //@inheritdoc ICredibleAccountHook
    function isModuleType(uint256 moduleTypeId) external view returns (bool) {
        return moduleTypeId == MODULE_TYPE_HOOK;
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the token balance of the caller
    /// @dev Uses the ERC20 balanceOf function to get the balance
    /// @param _token The address of the ERC20 token
    /// @return uint256 The balance of the token for the caller
    function _getTokenBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(msg.sender));
    }

    /// @notice Checks if the token balance is sufficient for a transaction
    /// @dev Compares the available balance against the locked amount plus the transaction amount
    /// @param _token The address of the token to check
    /// @param _txAmount The amount of tokens required for the transaction
    /// @return bool True if the balance is sufficient, false otherwise
    function _isBalanceSufficient(
        address _token,
        uint256 _txAmount
    ) internal view returns (bool) {
        uint256 balance = _getTokenBalance(_token);
        uint256 locked = retrieveLockedBalance(_token);
        return balance >= locked + _txAmount;
    }

    /// @notice Retrieves the count of locked tokens for a specific session key
    /// @dev Iterates through the locked tokens to count those associated with the given session key
    /// @param _sessionKey The session key to check for locked tokens
    /// @return uint256 The number of locked tokens for the specified session key
    function _getLockedTokenCount(
        address _sessionKey
    ) internal view returns (uint256) {
        LockedToken[] storage locks = lockedTokens[msg.sender];
        uint256 count;
        for (uint256 i; i < locks.length; ++i) {
            if (locks[i].sessionKey == _sessionKey) {
                ++count;
            }
        }
        return count;
    }

    /// @notice Checks and manages permitted Credible Account actions
    /// @dev Verifies if the action is a Credible Account operation and manages the lock state accordingly
    /// @param callType The type of call (single or batch)
    /// @param modeSelector The mode selector for the operation
    /// @param modePayload The payload associated with the mode
    /// @param executionData The data to be executed
    function _checkPermittedCredibleAccountAction(
        CallType callType,
        ModeSelector modeSelector,
        ModePayload modePayload,
        bytes calldata executionData
    ) internal {
        if (eqModeSelector(modeSelector, MODE_SELECTOR_CREDIBLE_ACCOUNT)) {
            _manageLockState(callType, modePayload, executionData);
        } else {
            if (callType == CALLTYPE_SINGLE) {
                (, , bytes calldata callData) = ExecutionLib.decodeSingle(
                    executionData
                );
                if (bytes4(callData[:4]) == CAV.enableSessionKey.selector) {
                    revert CredibleAccountHook_CannotEnableSessionKeyWithoutModeSelector();
                }
            } else if (callType == CALLTYPE_BATCH) {
                Execution[] calldata executions = ExecutionLib.decodeBatch(
                    executionData
                );
                for (uint256 i; i < executions.length; ++i) {
                    if (
                        bytes4(executions[i].callData[:4]) ==
                        CAV.enableSessionKey.selector
                    ) {
                        revert CredibleAccountHook_CannotEnableSessionKeyWithoutModeSelector();
                    }
                }
            }
        }
    }

    /// @notice Manages the lock state for Credible Account actions
    /// @dev Determines whether to lock or unlock tokens based on the provided mode payload
    /// @param _callType The type of call (single or batch)
    /// @param _modePayload The payload containing session key information
    /// @param _executionData The data for execution (lock or unlock instructions)
    function _manageLockState(
        CallType _callType,
        ModePayload _modePayload,
        bytes calldata _executionData
    ) internal {
        address sessionKey = address(
            uint160(uint176(ModePayload.unwrap(_modePayload)) >> 16)
        );
        if (sessionKey != address(0)) {
            if (!_tryUnlock(_callType, sessionKey, _executionData))
                revert CredibleAccountHook_UnsuccessfulUnlock();
        } else {
            if (!_tryLock(_callType, _executionData))
                revert CredibleAccountHook_UnsuccessfulLock();
        }
    }

    /// @notice Attempts to lock tokens based on the provided data
    /// @dev Handles both batch and single lock requests
    /// @param _callType The type of call (single or batch)
    /// @param _data The calldata containing lock instructions
    /// @return bool True if all locks are successful, false otherwise
    function _tryLock(
        CallType _callType,
        bytes calldata _data
    ) internal returns (bool) {
        if (_callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = ExecutionLib.decodeBatch(_data);
            uint256 length = executions.length;
            if (length == 0) return false;
            unchecked {
                for (uint256 i; i < length; ++i) {
                    if (!_lockTokens(executions[i].callData)) return false;
                }
            }
            return true;
        } else if (_callType == CALLTYPE_SINGLE) {
            (, , bytes calldata callData) = ExecutionLib.decodeSingle(_data);
            return _lockTokens(callData);
        } else {
            return false;
        }
    }

    /// @notice Attempts to unlock tokens based on the execution data
    /// @dev Processes single or batch unlock requests and reverts if any unlock fails
    /// @param _callType The type of call (single or batch)
    /// @param _sessionKey The session key associated with the locked tokens
    /// @param _executionData The data containing unlock instructions
    /// @return bool True if all unlocks are successful, false for unsupported call types
    function _tryUnlock(
        CallType _callType,
        address _sessionKey,
        bytes calldata _executionData
    ) internal returns (bool) {
        uint256 lockedTokenCount = _getLockedTokenCount(_sessionKey);
        if (lockedTokenCount == 0) return false;
        if (_callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = ExecutionLib.decodeBatch(
                _executionData
            );
            for (uint256 i; i < executions.length; ++i) {
                (, address receiver, uint256 amount) = _digestERC20Transaction(
                    executions[i].callData
                );
                bool unlockSuccess = _unlockTokens(
                    _sessionKey,
                    executions[i].target,
                    receiver,
                    amount
                );
                if (!unlockSuccess) {
                    revert CredibleAccountHook_UnsuccessfulUnlock();
                }
            }
            return true;
        } else if (_callType == CALLTYPE_SINGLE) {
            (address target, , bytes calldata callData) = ExecutionLib
                .decodeSingle(_executionData);
            (, address receiver, uint256 amount) = _digestERC20Transaction(
                callData
            );
            bool unlockSuccess = _unlockTokens(
                _sessionKey,
                target,
                receiver,
                amount
            );
            if (!unlockSuccess) {
                revert CredibleAccountHook_UnsuccessfulUnlock();
            }
            return true;
        } else {
            return false;
        }
    }

    /// @notice Locks tokens based on the provided data
    /// @dev Processes enableSessionKey data to lock tokens for a specific session key and solver
    /// @param _data The calldata containing session key and token locking information
    /// @return bool True if the locking process was successful, false otherwise
    function _lockTokens(bytes calldata _data) internal returns (bool) {
        if (bytes4(_data[:4]) != CAV.enableSessionKey.selector) return false;
        address sessionKey = address(bytes20(_data[68:88]));
        address solver = address(bytes20(_data[88:108]));
        uint256 tokenLen = uint256(bytes32(_data[124:156]));
        LockedToken[] storage userLocks = lockedTokens[msg.sender];
        uint256 userLocksLength = userLocks.length;
        for (uint256 i; i < userLocksLength; ) {
            if (userLocks[i].sessionKey == sessionKey)
                revert CredibleAccountHook_SessionKeyAlreadyExists(
                    msg.sender,
                    sessionKey
                );
            unchecked {
                ++i;
            }
        }
        uint256 offset = 156;
        for (uint256 i; i < tokenLen; ) {
            address token = address(
                uint160(uint256(bytes32(_data[offset:offset + 32])))
            );
            offset += 32;
            unchecked {
                ++i;
            }
            uint256 amount = uint256(
                bytes32(
                    _data[offset + tokenLen * 32:offset + tokenLen * 32 + 32]
                )
            );

            if (!_isBalanceSufficient(token, amount)) return false;
            LockedToken memory lock = LockedToken({
                sessionKey: sessionKey,
                solverAddress: solver,
                token: token,
                amount: amount
            });
            emit CredibleAccountHook_TokenLocked(
                msg.sender,
                sessionKey,
                token,
                amount
            );
            userLocks.push(lock);
            unchecked {
                ++transactionsInProgress[msg.sender];
            }
        }
        return true;
    }

    /// @notice Unlocks tokens for a specific session key
    /// @dev Attempts to unlock a specified amount of tokens for a given session key, token, and receiver
    /// @param _sessionKey The session key associated with the locked tokens
    /// @param _token The address of the token to unlock
    /// @param _receiver The address of the receiver (solver)
    /// @param _amount The amount of tokens to unlock
    /// @return bool True if the unlock was successful, false otherwise
    function _unlockTokens(
        address _sessionKey,
        address _token,
        address _receiver,
        uint256 _amount
    ) internal returns (bool) {
        LockedToken[] storage locks = lockedTokens[msg.sender];
        uint256 length = locks.length;
        if (length == 0) return false;
        if (_amount > _getTokenBalance(_token)) return false;
        for (uint256 i; i < length; ++i) {
            LockedToken storage lock = locks[i];
            if (
                lock.sessionKey == _sessionKey &&
                lock.token == _token &&
                lock.solverAddress == _receiver &&
                lock.amount >= _amount
            ) {
                if (lock.amount == _amount) {
                    locks[i] = locks[length - 1];
                    locks.pop();
                    transactionsInProgress[msg.sender] -= 1;
                } else {
                    lock.amount -= _amount;
                }
                return true;
            }
        }
        return false;
    }

    /// @notice Extracts ERC20 transaction details from calldata
    /// @dev Parses the calldata to identify transfer or transferFrom function calls and their parameters
    /// @param _data The calldata to be parsed
    /// @return selector The function selector (transfer or transferFrom)
    /// @return recipient The recipient address of the token transfer
    /// @return amount The amount of tokens being transferred
    function _digestERC20Transaction(
        bytes calldata _data
    )
        internal
        pure
        returns (bytes4 selector, address recipient, uint256 amount)
    {
        selector = bytes4(_data[:4]);
        if (selector == IERC20.transfer.selector) {
            recipient = address(bytes20(_data[16:36]));
            amount = uint256(bytes32(_data[36:68]));
        } else if (selector == IERC20.transferFrom.selector) {
            recipient = address(bytes20(_data[48:68]));
            amount = uint256(bytes32(_data[68:100]));
        } else {
            recipient = address(0);
            amount = type(uint256).max;
        }
    }

    /// @notice Encodes the initial locked state of tokens for the caller
    /// @dev This function creates a snapshot of the current token balances for all locked tokens
    /// @return bytes The ABI-encoded array of TokenBalance structs representing the initial locked state
    function _encodeInitialLockedState() internal view returns (bytes memory) {
        TokenBalance[] memory initialBalances = new TokenBalance[](
            lockedTokens[msg.sender].length
        );
        for (uint256 i; i < lockedTokens[msg.sender].length; ++i) {
            address token = lockedTokens[msg.sender][i].token;
            uint256 balance = IERC20(token).balanceOf(msg.sender);
            initialBalances[i] = TokenBalance(token, balance);
        }
        return abi.encode(initialBalances);
    }
}
