// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC1271Wallet {
    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bytes4 magicValue);
}
