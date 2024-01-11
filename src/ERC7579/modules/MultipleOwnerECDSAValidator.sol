// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IValidator, IERC4337, VALIDATION_SUCCESS, VALIDATION_FAILED} from "@ERC7579/src/interfaces/IModule.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {EtherspotWallet7579} from "../wallet/EtherspotWallet7579.sol";

contract MultipleOwnerECDSAValidator is IValidator {
    using ECDSA for bytes32;

    function onInstall(bytes calldata data) external override {}

    function onUninstall(bytes calldata data) external override {}

    function validateUserOp(
        IERC4337.UserOperation calldata userOp,
        bytes32 userOpHash
    ) external view override returns (uint256) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(userOp.signature);
        if (
            signer == address(0) ||
            !EtherspotWallet7579(msg.sender).isOwner(signer)
        ) {
            return VALIDATION_FAILED;
        }
        return VALIDATION_SUCCESS;
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view override returns (bytes4) {}
}
