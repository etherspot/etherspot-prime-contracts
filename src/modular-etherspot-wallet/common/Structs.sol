// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title SessionData
/// @notice Struct containing all data related to a session key
/// @dev Used to manage and validate session keys
struct SessionData {
    address sessionKey; // The address of the session key
    uint48 validAfter; // The timestamp after which the session key is valid
    uint48 validUntil; // The timestamp until which the session key is valid
    bool live; // Flag indicating whether the session key is active or paused
}

/// @title TokenData
/// @notice Struct containing basic token information
/// @dev Used to store token addresses and corresponding amounts
struct TokenData {
    address token;
    uint256 amount;
}
