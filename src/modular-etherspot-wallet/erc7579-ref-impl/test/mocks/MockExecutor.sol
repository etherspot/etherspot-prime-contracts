// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IExecutor, EncodedModuleTypes} from "../../interfaces/IERC7579Module.sol";
import {IERC7579Account, Execution} from "../../interfaces/IERC7579Account.sol";
import {ExecutionLib} from "../../libs/ExecutionLib.sol";
import {ModeLib} from "../../libs/ModeLib.sol";

contract MockExecutor is IExecutor {
    function onInstall(bytes calldata data) external override {}

    function onUninstall(bytes calldata data) external override {}

    function executeViaAccount(
        IERC7579Account account,
        address target,
        uint256 value,
        bytes calldata callData
    ) external returns (bytes[] memory returnData) {
        return
            account.executeFromExecutor(
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(target, value, callData)
            );
    }

    function execBatch(
        IERC7579Account account,
        Execution[] calldata execs
    ) external returns (bytes[] memory returnData) {
        return
            account.executeFromExecutor(
                ModeLib.encodeSimpleBatch(),
                ExecutionLib.encodeBatch(execs)
            );
    }

    function isModuleType(uint256 typeID) external view returns (bool) {
        return typeID == 2;
    }

    function getModuleTypes() external view returns (EncodedModuleTypes) {}

    function isInitialized(address smartAccount) external view returns (bool) {
        return false;
    }
}
