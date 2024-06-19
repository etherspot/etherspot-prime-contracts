// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IExecutor, MODULE_TYPE_EXECUTOR} from "../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {IERC7579Account, Execution} from "../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {ExecutionLib} from "../erc7579-ref-impl/libs/ExecutionLib.sol";
import {ModeLib, CALLTYPE_DELEGATECALL, EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload} from "../erc7579-ref-impl/libs/ModeLib.sol";

contract TestExecutor is IExecutor {
    mapping(address => bool) public initialized;

    function onInstall(bytes calldata data) external override {
        initialized[msg.sender] = true;
    }

    function onUninstall(bytes calldata data) external override {
        initialized[msg.sender] = false;
    }

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

    function execDelegatecall(
        IERC7579Account account,
        bytes calldata callData
    ) external returns (bytes[] memory returnData) {
        return
            account.executeFromExecutor(
                ModeLib.encode(
                    CALLTYPE_DELEGATECALL,
                    EXECTYPE_DEFAULT,
                    MODE_DEFAULT,
                    ModePayload.wrap(0x00)
                ),
                callData
            );
    }

    function isModuleType(uint256 moduleTypeId) external view returns (bool) {
        return moduleTypeId == MODULE_TYPE_EXECUTOR;
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        return initialized[smartAccount];
    }
}
