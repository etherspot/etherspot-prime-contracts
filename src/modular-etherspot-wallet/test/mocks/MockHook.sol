// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IHook as IERC7579Hook, MODULE_TYPE_HOOK } from  "../../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {
    ModeLib,
    CallType,
    ModeCode,
    CALLTYPE_SINGLE,
    CALLTYPE_BATCH,
    CALLTYPE_DELEGATECALL,
    ModeSelector
} from "../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";
import { ERC7579HookBase } from "../../../../src/modular-etherspot-wallet/modules/hooks/ERC7579HookBase.sol";

contract MockHook is ERC7579HookBase {
    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function _preCheck(
        address account,
        address msgSender,
        uint256 msgValue,
        bytes calldata msgData
    )
        internal
        override
        returns (bytes memory hookData)
    {
        ModeSelector mode = ModeSelector.wrap(bytes4(msgData[10:14]));

        if (mode == ModeSelector.wrap(bytes4(keccak256(abi.encode("revert"))))) {
            revert("revert");
        } else if (mode == ModeSelector.wrap(bytes4(keccak256(abi.encode("revertPost"))))) {
            hookData = abi.encode("revertPost");
        } else {
            hookData = abi.encode("success");
        }
    }

    function _postCheck(address account, bytes calldata hookData) internal override {
        if (keccak256(hookData) == keccak256(abi.encode("revertPost"))) {
            revert("revertPost");
        }
    }

    function isInitialized(address smartAccount) external pure returns (bool) {
        return false;
    }

    function isModuleType(uint256 typeID) external pure returns (bool) {
        return typeID == MODULE_TYPE_HOOK;
    }
}
