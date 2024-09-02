// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";
import {MODE_SELECTOR_MTSKV} from "../../common/Constants.sol";

import "forge-std/console2.sol";

contract TokenLockHook is IHook {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct LockedToken {
        address sessionKey;
        address solverAddress;
        address token;
        uint256 amount;
    }

    /*//////////////////////////////////////////////////////////////
                               MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public installed;
    mapping(address => LockedToken[]) public lockedTokens;
    mapping(address => bool) public transactionsInProgress;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error TLH_TokenIsNotLocked(address sessionKey, address token);
    error TLH_CantUninstallWhileTransactionInProgress(address wallet);
    error TLH_TransactionInProgress(address wallet, address token);
    error TLH_InvalidCallType(CallType callType);

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TLH_ModuleInstalled(address indexed wallet);
    event TLH_ModuleUninstalled(address indexed wallet);
    event TLH_TokenLocked(
        address indexed wallet,
        address indexed sessionKey,
        address indexed token,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                           PUBLIC/EXTERNAL
    //////////////////////////////////////////////////////////////*/

    // TODO: on preCheck:
    // - check ModeSelector
    // - - if MultiTokenSessionKeyValidator
    // - - - check SINGLE or BATCH
    // - - - - decode Execution(s)
    // - - - - check if selector is enableSessionKey
    // - - - - - if true, lock tokens/amounts
    // - - - - - if false and flagged (possibly using ModePayload), unlock tokens/amounts
    // - - - - - if false and not flagged, check against constraints
    // - - if not MultiTokenSessionKeyValidator
    // - - - check SINGLE or BATCH
    // - - - - decode Execution(s)
    // - - - - check tokens in Execution(s) against lockedTokens
    // - - - - - if locked tokens, check against constraints
    // - - - - - - if failed against constraints, revert
    // - - - - - - if passed constraints, allow
    // - - - - - if not locked tokens, allow

    // TODO: pain points
    // make sure enableSessionKey provides correct data to store for data structures?
    // how to know what function call and data is to check against locked token constraints?
    // - limit to IERC20 transfer/transfer from for now?
    // - use some combination (like in ParamConditions) and SuperValidator to provide location of token/amount data?
    // use ModeSelector/ModePayload to provide unlocking tx flag?
    // lock specified amounts for a token so can validate if complies with locked balance?
    // pass in token amounts on enableSessionKey and check fx amount valid against USD?

    function isTokenLocked(
        address wallet,
        address _token
    ) public view returns (bool) {
        LockedToken[] memory tokens = lockedTokens[wallet];
        for (uint256 i; i < tokens.length; ++i) {
            if (tokens[i].token == _token && tokens[i].amount > 0) {
                return true;
            }
            return false;
        }
    }

    function isTransactionInProgress() public view returns (bool) {
        return transactionsInProgress[msg.sender];
    }

    // TODO
    function unlockToken(address _wallet, address _token) external {
        // TODO: Implement authorization check
        if (!isTokenLocked(_wallet, _token))
            revert TLH_TokenIsNotLocked(_wallet, _token);
        delete lockedTokens[_wallet];
        delete transactionsInProgress[_wallet];
    }

    function preCheck(
        address msgSender,
        uint256 msgValue,
        bytes calldata msgData
    ) external override returns (bytes memory hookData) {
        ModeCode mode = ModeCode.wrap(bytes32(msgData[4:36]));
        (CallType callType, , ModeSelector modeSelector, ) = mode.decode();
        if (eqModeSelector(modeSelector, MODE_SELECTOR_MTSKV)) {
            _handleMultiTokenSessionKeyValidator(callType, msgData[100:]);
        } else {
            return _checkLockedTokens(callType, msgData[100:]);
        }
    }

    function postCheck(bytes calldata hookData) external {}

    // @inheritdoc IModule
    function onInstall(bytes calldata data) external override {
        installed[msg.sender] = true;
        emit TLH_ModuleInstalled(msg.sender);
    }

    // @inheritdoc IModule
    function onUninstall(bytes calldata data) external override {
        if (isTransactionInProgress())
            revert TLH_CantUninstallWhileTransactionInProgress(msg.sender);
        installed[msg.sender] = false;
        delete lockedTokens[msg.sender];
        delete transactionsInProgress[msg.sender];
        emit TLH_ModuleUninstalled(msg.sender);
    }

    // @inheritdoc IModule
    function isInitialized(
        address smartAccount
    ) external view override returns (bool) {
        return installed[smartAccount];
    }

    // @inheritdoc IModule
    function isModuleType(uint256 moduleTypeId) external view returns (bool) {
        return moduleTypeId == MODULE_TYPE_HOOK;
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNAL
    //////////////////////////////////////////////////////////////*/

    // TODO: need to replace logic with only locking tokens
    // on enableSessionKey function from MultiTokenSessionKeyValidator
    // rather than current approach of locking tokens on
    // erc20 transfer or transferFrom call from MultiTokenSessionKeyValidator
    // TODO: decide on data passed into enableSesionKey
    function _handleMultiTokenSessionKeyValidator(
        CallType _callType,
        bytes calldata _executionData
    ) internal {
        if (_callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = ExecutionLib.decodeBatch(
                _executionData
            );
            for (uint256 i; i < executions.length; ++i) {
                _lockToken(
                    executions[i].target,
                    _getTokenAmount(executions[i].callData)
                );
            }
        } else if (_callType == CALLTYPE_SINGLE) {
            (
                address target,
                uint256 value,
                bytes calldata callData
            ) = ExecutionLib.decodeSingle(_executionData);
            _lockToken(target, _getTokenAmount(callData));
        } else {
            revert TLH_InvalidCallType(_callType);
        }
    }

    function _checkLockedTokens(
        CallType _callType,
        bytes calldata _executionData
    ) internal view returns (bytes memory) {
        if (_callType == CALLTYPE_BATCH) {
            Execution[] memory executions = ExecutionLib.decodeBatch(
                _executionData
            );
            for (uint256 i; i < executions.length; ++i) {
                if (isTransactionInProgress())
                    revert TLH_TransactionInProgress(
                        msg.sender,
                        executions[i].target
                    );
                return "";
            }
        } else if (_callType == CALLTYPE_SINGLE) {
            (address target, , ) = ExecutionLib.decodeSingle(_executionData);
            if (isTransactionInProgress())
                revert TLH_TransactionInProgress(msg.sender, target);

            return "";
        } else {
            revert TLH_InvalidCallType(_callType);
        }
    }

    function _lockToken(
        address _sessionKey,
        address _solver,
        address _token,
        uint256 _amount
    ) internal {
        if (transactionsInProgress[msg.sender])
            revert TLH_TransactionInProgress(msg.sender, _token);
        lockedTokens[msg.sender] = LockedToken(
            _sessionKey,
            _solver,
            _token,
            _amount
        );
        transactionsInProgress[msg.sender] = true;
        emit TLH_TokenLocked(msg.sender, _token, _amount);
    }

    function _getTokenAmount(
        bytes calldata _data
    ) internal pure returns (uint256) {
        bytes4 selector = bytes4(_data[:4]);
        if (selector == IERC20.transfer.selector) {
            return uint256(bytes32(_data[36:68]));
        } else if (selector == IERC20.transferFrom.selector) {
            return uint256(bytes32(_data[68:100]));
        }
        return 0;
    }

    function _getTokenBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(msg.sender));
    }

    function _retrieveLockedBalance(
        address _token
    ) internal view returns (uint256) {
        for (uint256 i; i < lockedTokens[msg.sender].length; ++i) {
            if (lockedTokens[msg.sender][i].token == _token) {
                return lockedTokens[msg.sender][i].amount;
            }
            return type(uint256).max;
        }
    }

    function _isBalanceSufficient(
        address _token,
        uint256 _txAmount
    ) internal view returns (bool) {
        uint256 balance = _getTokenBalance(_token);
        uint256 locked = _retrieveLockedBalance(_token);
        return balance >= locked + _txAmount;
    }
}
