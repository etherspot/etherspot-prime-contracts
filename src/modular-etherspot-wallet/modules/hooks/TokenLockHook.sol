// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";

import "forge-std/console2.sol";

contract TokenLockHook is IHook {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /*//////////////////////////////////////////////////////////////
                               MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public installed;
    mapping(address => mapping(address => uint256)) public lockedTokens;
    mapping(address => address[]) public lockedTokensForWallet;
    mapping(address => bool) public transactionsInProgress;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

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
        address indexed token,
        uint256 indexed amount
    );

    /*//////////////////////////////////////////////////////////////
                           PUBLIC/EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function isTokenLocked(address _token) public view returns (bool) {
        return lockedTokens[msg.sender][_token] > 0;
    }

    function isTransactionInProgress() public view returns (bool) {
        return transactionsInProgress[msg.sender];
    }

    // TODO
    function unlockToken(address _wallet, address _token) external {
        // TODO: Implement authorization check
        delete lockedTokens[_wallet][_token];
        for (uint256 i; i < lockedTokensForWallet[_wallet].length; ++i) {
            if (lockedTokensForWallet[_wallet][i] == _token) {
                delete lockedTokensForWallet[_wallet][i];
            }
            delete transactionsInProgress[_wallet];
        }
    }

    function preCheck(
        address msgSender,
        uint256 msgValue,
        bytes calldata msgData
    ) external override returns (bytes memory hookData) {
        ModeCode mode = ModeCode.wrap(bytes32(msgData[4:36]));
        (CallType callType, , ModeSelector modeSelector, ) = mode.decode();
        if (
            modeSelector ==
            ModeSelector.wrap(
                bytes4(keccak256("etherspot.multitokensessionkeyvalidator"))
            )
        ) {
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
        if (transactionsInProgress[msg.sender])
            revert TLH_CantUninstallWhileTransactionInProgress(msg.sender);
        installed[msg.sender] = false;
        for (uint256 i; i < lockedTokensForWallet[msg.sender].length; i++) {
            delete lockedTokens[msg.sender][
                lockedTokensForWallet[msg.sender][i]
            ];
        }
        delete lockedTokensForWallet[msg.sender];
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
                if (lockedTokens[msg.sender][executions[i].target] > 0) {
                    revert TLH_TransactionInProgress(
                        msg.sender,
                        executions[i].target
                    );
                } else {
                    return "";
                }
            }
        } else if (_callType == CALLTYPE_SINGLE) {
            (address target, , ) = ExecutionLib.decodeSingle(_executionData);
            if (lockedTokens[msg.sender][target] > 0) {
                revert TLH_TransactionInProgress(msg.sender, target);
            } else {
                return "";
            }
        } else {
            revert TLH_InvalidCallType(_callType);
        }
    }

    function _lockToken(address _token, uint256 _amount) internal {
        if (lockedTokens[msg.sender][_token] > 0) {
            revert TLH_TransactionInProgress(msg.sender, _token);
        }
        lockedTokens[msg.sender][_token] = _amount;
        lockedTokensForWallet[msg.sender].push(_token);
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
}
