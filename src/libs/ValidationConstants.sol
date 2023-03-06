// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Account
 *
 * @author Stanisław Głogowski <stan@pillarproject.io>
 */
library ValidationConstants {
    bytes32 public constant ERC777_TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256(abi.encodePacked("ERC777TokensRecipient"));
    bytes32 public constant ERC1820_ACCEPT_MAGIC =
        keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

    bytes4 public constant ERC1271_VALID_MESSAGE_HASH_SIGNATURE =
        bytes4(keccak256(abi.encodePacked("isValidSignature(bytes32,bytes)")));
    bytes4 public constant ERC1271_VALID_MESSAGE_SIGNATURE =
        bytes4(keccak256(abi.encodePacked("isValidSignature(bytes,bytes)")));
    bytes4 public constant ERC1271_INVALID_SIGNATURE = 0xffffffff;
}
