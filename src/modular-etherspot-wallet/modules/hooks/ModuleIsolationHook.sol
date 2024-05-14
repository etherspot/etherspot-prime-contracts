// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title ModuleIsolationHook
/// @author windowhan (https://github.com/windowhan) (modifications by lbw33)
/// @notice Custom hook to prevent modules from installing/uninstalling other modules
/// @dev Implements preCheck hook to block restricted function calls

import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";

contract ModuleIsolationHook is IHook {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /// @notice Records which modules this hook is installed for
    mapping(address => bool) public installed;

    /// @notice Called when this hook is installed for a module
    function onInstall(bytes calldata data) external override {
        installed[msg.sender] = true;
    }

    /// @notice Called when this hook is uninstalled for a module
    function onUninstall(bytes calldata data) external override {
        installed[msg.sender] = false;
    }
    /// @notice Checks if a signature is in a list
    /// @param target Signature to check for
    /// @param list List of signatures
    /// @return bool True if target is in the list
    function contains(
        bytes4 target,
        bytes4[] memory list
    ) public view returns (bool) {
        for (uint i; i < list.length; i++) {
            if (target == list[i]) return true;
        }
        return false;
    }

    /// @notice Main pre-call check for restricted signatures
    /// @param msgSender Message sender address
    /// @param msgData Message data
    function preCheck(
        address msgSender,
        bytes calldata msgData
    ) external override returns (bytes memory hookData) {
        bytes4 firstFuncSig = bytes4(msgData[0:4]);
        if (
            firstFuncSig == ModularEtherspotWallet.executeFromExecutor.selector
        ) {
            ModeCode mode = ModeCode.wrap(bytes32(msgData[4:36]));
            (CallType callType, ExecType execType, , ) = mode.decode();
            integrityCheck(callType, msgData[68 + 32:]);
        }
        return "";
    }

    /// @notice Checks message data and reverts on restricted signatures
    /// @param callType Call type
    /// @param executionCallData Call data
    function integrityCheck(
        CallType callType,
        bytes calldata executionCallData
    ) public {
        bytes4[] memory bannedSigs = new bytes4[](5);
        bannedSigs[0] = ModularEtherspotWallet.execute.selector;
        bannedSigs[1] = ModularEtherspotWallet.executeFromExecutor.selector;
        bannedSigs[2] = ModularEtherspotWallet.executeUserOp.selector;
        bannedSigs[3] = ModularEtherspotWallet.installModule.selector;
        bannedSigs[4] = ModularEtherspotWallet.uninstallModule.selector;

        if (callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = executionCallData.decodeBatch();
            for (uint i; i < executions.length; i++) {
                bytes4 checkSig = bytes4(executions[i].callData[0]) |
                    (bytes4(executions[i].callData[1]) >> 8) |
                    (bytes4(executions[i].callData[2]) >> 16) |
                    (bytes4(executions[i].callData[3]) >> 24);
                require(
                    !contains(checkSig, bannedSigs),
                    "MEW::ModuleIsolationHook:BannedSignature"
                );
            }
        } else if (callType == CALLTYPE_SINGLE) {
            (
                address target,
                uint256 value,
                bytes calldata callData
            ) = executionCallData.decodeSingle();

            bytes4 checkSig = bytes4(callData[0]) |
                (bytes4(callData[1]) >> 8) |
                (bytes4(callData[2]) >> 16) |
                (bytes4(callData[3]) >> 24);
            require(
                !contains(checkSig, bannedSigs),
                "MEW::ModuleIsolationHook:BannedSignature"
            );
        } else if (callType == CALLTYPE_DELEGATECALL) {
            bytes4 checkSig = bytes4(executionCallData[0]) |
                (bytes4(executionCallData[1]) >> 8) |
                (bytes4(executionCallData[2]) >> 16) |
                (bytes4(executionCallData[3]) >> 24);
            require(
                !contains(checkSig, bannedSigs),
                "MEW::ModuleIsolationHook:BannedSignature"
            );
        }
    }

    /// @notice Main pre-call check for restricted signatures
    /// @param hookData Message sender address
    function postCheck(
        bytes calldata hookData
    ) external returns (bool success) {}

    /// @notice Checks if this contract is a hook module type
    /// @param typeID Module type ID
    /// @return bool True if module type is HOOK
    function isModuleType(
        uint256 typeID
    ) external view override returns (bool) {
        return MODULE_TYPE_HOOK == typeID;
    }

    /// @notice Checks if this hook is installed for a wallet
    /// @param smartAccount Wallet address
    /// @return bool True if this hook is installed for the wallet
    function isInitialized(
        address smartAccount
    ) external view override returns (bool) {
        return installed[smartAccount];
    }
}
