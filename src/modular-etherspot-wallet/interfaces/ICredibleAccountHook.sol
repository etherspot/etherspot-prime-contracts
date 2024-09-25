// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../erc7579-ref-impl/libs/ModeLib.sol";
import "../erc7579-ref-impl/interfaces/IERC7579Module.sol";

/// @title ICredibleAccountHook
/// @author Etherspot
/// @notice Interface for the CredibleAccountHook contract
interface ICredibleAccountHook is IHook {
    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct representing a locked token
    struct LockedToken {
        address sessionKey;
        address solverAddress;
        address token;
        uint256 amount;
    }

    /// @notice Struct representing a token balance
    struct TokenBalance {
        address token;
        uint256 balance;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the module is installed
    event CredibleAccountHook_ModuleInstalled(address indexed wallet);

    /// @notice Emitted when the module is uninstalled
    event CredibleAccountHook_ModuleUninstalled(address indexed wallet);

    /// @notice Emitted when a token is locked
    event CredibleAccountHook_TokenLocked(
        address indexed wallet,
        address indexed sessionKey,
        address indexed token,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if a token is locked for a specific wallet
    /// @param wallet The address of the wallet
    /// @param _token The address of the token
    /// @return bool True if the token is locked, false otherwise
    function isTokenLocked(
        address wallet,
        address _token
    ) external view returns (bool);

    /// @notice Retrieves the locked balance of a token
    /// @param _token The address of the token
    /// @return uint256 The total locked balance of the token
    function retrieveLockedBalance(
        address _token
    ) external view returns (uint256);

    /// @notice Checks if the module is initialized for a smart account
    /// @param smartAccount The address of the smart account
    /// @return bool True if initialized, false otherwise
    function isInitialized(address smartAccount) external view returns (bool);

    /// @notice Checks if the module is of a specific type
    /// @param moduleTypeId The ID of the module type
    /// @return bool True if the module is of the specified type, false otherwise
    function isModuleType(uint256 moduleTypeId) external view returns (bool);
}
