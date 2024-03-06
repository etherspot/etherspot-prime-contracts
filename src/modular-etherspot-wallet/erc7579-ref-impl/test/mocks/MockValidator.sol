// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IValidator, PackedUserOperation, VALIDATION_SUCCESS, EncodedModuleTypes} from "../../interfaces/IERC7579Module.sol";

contract MockValidator is IValidator {
    function onInstall(bytes calldata data) external override {}

    function onUninstall(bytes calldata data) external override {}

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256) {
        bytes4 execSelector = bytes4(userOp.callData[:4]);

        return VALIDATION_SUCCESS;
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view override returns (bytes4) {}

    function isModuleType(uint256 typeID) external view returns (bool) {
        return typeID == 1;
    }

    function getModuleTypes() external view returns (EncodedModuleTypes) {}

    function isInitialized(address smartAccount) external view returns (bool) {
        return false;
    }
}
