// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";
import {TokenLockSessionKeyValidator as TLSKV} from "../validators/TokenLockSessionKeyValidator.sol";
import {MODE_SELECTOR_MTSKV} from "../../common/Constants.sol";

contract TokenLockHook is IHook {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    struct LockedToken {
        address sessionKey;
        address solverAddress;
        address token;
        uint256 amount;
    }

    mapping(address => bool) public installed;
    mapping(address => LockedToken[]) public lockedTokens;
    mapping(address => uint256) public transactionsInProgress;

    error TLH_TokenIsNotLocked(address sessionKey, address token);
    error TLH_CantUninstallWhileTransactionInProgress(address wallet);
    error TLH_TransactionInProgress(address wallet, address token);
    error TLH_InvalidCallType(CallType callType);
    error TLH_UnsuccessfulUnlock();
    error TLH_UnsuccessfulLock();
    error TLH_InsufficientUnlockedBalance(address token);
    error TLH_CannotEnableSessionKeyWithoutModeSelector();
    error TLH_SessionKeyAlreadyExists(address wallet, address sessionKey);

    event TLH_ModuleInstalled(address indexed wallet);
    event TLH_ModuleUninstalled(address indexed wallet);
    event TLH_TokenLocked(
        address indexed wallet,
        address indexed sessionKey,
        address indexed token,
        uint256 amount
    );

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

    function isTransactionInProgress(
        address _wallet
    ) public view returns (bool) {
        return transactionsInProgress[_wallet] > 0;
    }

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
        if (eqModeSelector(modeSelector, MODE_SELECTOR_MTSKV)) {
            _manageLockState(callType, modePayload, msgData[100:]);
        } else {
            if (!_checkForUninstallHook(callType, msgData[100:])) {
                return _checkLockedTokens(callType, msgData[100:]);
            } else {
                if (isTransactionInProgress(msg.sender))
                    revert TLH_CantUninstallWhileTransactionInProgress(
                        msg.sender
                    );
                return "";
            }
        }
    }

    function postCheck(bytes calldata hookData) external {}

    function onInstall(bytes calldata data) external override {
        installed[msg.sender] = true;
        emit TLH_ModuleInstalled(msg.sender);
    }

    function onUninstall(bytes calldata data) external override {
        if (transactionsInProgress[msg.sender] > 0)
            revert TLH_CantUninstallWhileTransactionInProgress(msg.sender);
        installed[msg.sender] = false;
        delete lockedTokens[msg.sender];
        delete transactionsInProgress[msg.sender];
        emit TLH_ModuleUninstalled(msg.sender);
    }

    function isInitialized(
        address smartAccount
    ) external view override returns (bool) {
        return installed[smartAccount];
    }

    function isModuleType(uint256 moduleTypeId) external view returns (bool) {
        return moduleTypeId == MODULE_TYPE_HOOK;
    }

    function _checkLockedTokens(
        CallType _callType,
        bytes calldata _executionData
    ) internal view returns (bytes memory) {
        bytes4 selector;
        address receiver;
        uint256 txAmount;

        if (_callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = ExecutionLib.decodeBatch(
                _executionData
            );
            unchecked {
                for (uint256 i; i < executions.length; ++i) {
                    (selector, receiver, txAmount) = _digestERC20Transaction(
                        executions[i].callData
                    );
                    address target = executions[i].target;
                    if (!_checkExecution(selector, receiver, txAmount, target))
                        return "";
                }
            }
        } else if (_callType == CALLTYPE_SINGLE) {
            (address target, , bytes calldata callData) = ExecutionLib
                .decodeSingle(_executionData);
            (selector, receiver, txAmount) = _digestERC20Transaction(callData);
            if (!_checkExecution(selector, receiver, txAmount, target))
                return "";
        } else {
            revert TLH_InvalidCallType(_callType);
        }
        return "";
    }

    function _checkExecution(
        bytes4 selector,
        address receiver,
        uint256 txAmount,
        address target
    ) private view returns (bool) {
        if (selector == TLSKV.enableSessionKey.selector) {
            revert TLH_CannotEnableSessionKeyWithoutModeSelector();
        }
        if (receiver == address(0)) return false;
        if (isTokenLocked(msg.sender, target)) {
            if (!_isBalanceSufficient(target, txAmount)) {
                revert TLH_InsufficientUnlockedBalance(target);
            }
        }
        return true;
    }

    function _getTokenBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(msg.sender));
    }

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

    function _isBalanceSufficient(
        address _token,
        uint256 _txAmount
    ) internal view returns (bool) {
        uint256 balance = _getTokenBalance(_token);
        uint256 locked = retrieveLockedBalance(_token);
        return balance >= locked + _txAmount;
    }

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
                revert TLH_UnsuccessfulUnlock();
        } else {
            if (!_tryLock(_callType, _executionData))
                revert TLH_UnsuccessfulLock();
        }
    }

    function _tryUnlock(
        CallType _callType,
        address _sessionKey,
        bytes calldata _executionData
    ) internal returns (bool) {
        uint256 lockedTokenCount = _getLockedTokenCount(_sessionKey);
        if (lockedTokenCount == 0) return false;
        uint256 unlockCount;
        if (_callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = ExecutionLib.decodeBatch(
                _executionData
            );
            if (executions.length != lockedTokenCount) return false;
            unchecked {
                for (uint256 i; i < executions.length; ++i) {
                    (
                        ,
                        address receiver,
                        uint256 amount
                    ) = _digestERC20Transaction(executions[i].callData);
                    if (
                        !_unlockTokens(
                            _sessionKey,
                            executions[i].target,
                            receiver,
                            amount
                        )
                    ) return false;
                    ++unlockCount;
                }
            }
        } else if (_callType == CALLTYPE_SINGLE) {
            if (lockedTokenCount != 1) return false;
            (address target, , bytes calldata callData) = ExecutionLib
                .decodeSingle(_executionData);
            (, address receiver, uint256 amount) = _digestERC20Transaction(
                callData
            );
            if (!_unlockTokens(_sessionKey, target, receiver, amount))
                return false;
            unlockCount = 1;
        } else {
            return false;
        }
        return unlockCount == lockedTokenCount;
    }

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
        unchecked {
            for (uint256 i; i < length; ++i) {
                LockedToken storage lock = locks[i];
                if (
                    lock.sessionKey == _sessionKey &&
                    lock.token == _token &&
                    lock.solverAddress == _receiver &&
                    lock.amount == _amount
                ) {
                    locks[i] = locks[length - 1];
                    locks.pop();
                    transactionsInProgress[msg.sender] -= 1;
                    return true;
                }
            }
        }
        return false;
    }

    function _lockTokens(bytes calldata _data) internal returns (bool) {
        if (bytes4(_data[:4]) != TLSKV.enableSessionKey.selector) return false;
        address sessionKey = address(bytes20(_data[68:88]));
        address solver = address(bytes20(_data[88:108]));
        uint256 tokenLen = uint256(bytes32(_data[124:156]));
        LockedToken[] storage userLocks = lockedTokens[msg.sender];
        uint256 userLocksLength = userLocks.length;
        for (uint256 i; i < userLocksLength; ) {
            if (userLocks[i].sessionKey == sessionKey)
                revert TLH_SessionKeyAlreadyExists(msg.sender, sessionKey);
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
            emit TLH_TokenLocked(msg.sender, sessionKey, token, amount);
            userLocks.push(lock);
            unchecked {
                ++transactionsInProgress[msg.sender];
            }
        }
        return true;
    }

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

    function _checkForUninstallHook(
        CallType _callType,
        bytes calldata _data
    ) internal pure returns (bool) {
        bytes4 uninstallSelector = ModularEtherspotWallet
            .uninstallModule
            .selector;
        if (_callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = ExecutionLib.decodeBatch(_data);
            uint256 length = executions.length;
            for (uint256 i; i < length; ) {
                if (bytes4(executions[i].callData[:4]) == uninstallSelector) {
                    return true;
                }
                unchecked {
                    ++i;
                }
            }
        } else if (_callType == CALLTYPE_SINGLE) {
            (, , bytes calldata callData) = ExecutionLib.decodeSingle(_data);
            return bytes4(callData[:4]) == uninstallSelector;
        }
        return false;
    }
}
