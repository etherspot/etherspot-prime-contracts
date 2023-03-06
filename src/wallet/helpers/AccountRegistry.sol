// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract AccountRegistry {
    /**
     * @notice Verifies account signature
     * @param account account address
     * @param messageHash message hash
     * @param signature signature
     * @return true if valid
     */
    function isValidAccountSignature(
        address account,
        bytes32 messageHash,
        bytes calldata signature
    ) external view virtual returns (bool);

    /**
     * @notice Verifies account signature
     * @param account account address
     * @param message message
     * @param signature signature
     * @return true if valid
     */
    function isValidAccountSignature(
        address account,
        bytes calldata message,
        bytes calldata signature
    ) external view virtual returns (bool);
}
