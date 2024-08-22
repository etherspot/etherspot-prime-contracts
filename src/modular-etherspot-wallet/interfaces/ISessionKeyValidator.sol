// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IValidator} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {ExecutionValidation, ParamCondition, Permission, SessionData} from "../common/Structs.sol";

interface ISessionKeyValidator is IValidator {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a module is installed
    /// @param wallet The address of the wallet where the module is installed
    event SKV_ModuleInstalled(address indexed wallet);

    /// @notice Emitted when a module is uninstalled
    /// @param wallet The address of the wallet where the module is uninstalled
    event SKV_ModuleUninstalled(address indexed wallet);

    /// @notice Emitted when a session key is enabled
    /// @param sessionKey The address of the enabled session key
    /// @param wallet The address of the wallet
    event SKV_SessionKeyEnabled(
        address indexed sessionKey,
        address indexed wallet
    );

    /// @notice Emitted when a session key is disabled
    /// @param sessionKey The address of the disabled session key
    /// @param wallet The address of the wallet
    event SKV_SessionKeyDisabled(
        address indexed sessionKey,
        address indexed wallet
    );

    /// @notice Emitted when a session key's pause status is toggled
    /// @param sessionKey The address of the session key
    /// @param wallet The address of the wallet
    /// @param live The new live status of the session key
    event SKV_SessionKeyPauseToggled(
        address indexed sessionKey,
        address indexed wallet,
        bool live
    );

    /// @notice Emitted when a Permission's uses are updated
    /// @param sessionKey The address of the session key
    /// @param index The index of the permission that was updated
    /// @param previousUses The previous number of uses
    /// @param newUses The new number of uses
    event SKV_PermissionUsesUpdated(
        address indexed sessionKey,
        uint256 index,
        uint256 previousUses,
        uint256 newUses
    );

    /// @notice Emitted when a session key's validUntil timestamp is updated
    /// @param sessionKey The address of the session key that was updated
    /// @param wallet The address of the wallet associated with the session key
    /// @param newValidUntil The new timestamp until which the session key is valid
    event SKV_SessionKeyValidUntilUpdated(
        address indexed sessionKey,
        address indexed wallet,
        uint48 newValidUntil
    );

    /// @notice Emitted when a new permission is added to a session key
    /// @param sessionKey The address of the session key to which the permission was added
    /// @param wallet The address of the wallet associated with the session key
    /// @param target The target contract address for the new permission
    /// @param selector The function selector for the new permission
    /// @param payableLimit The maximum amount of Ether that can be spent by the permission
    /// @param uses  The number of times the permission can be used
    /// @param paramConditions The conditions that must be met for the permission to be valid
    event SKV_PermissionAdded(
        address indexed sessionKey,
        address indexed wallet,
        address indexed target,
        bytes4 selector,
        uint256 payableLimit,
        uint256 uses,
        ParamCondition[] paramConditions
    );

    /// @notice Emitted when a permission is removed from a session key
    /// @param sessionKey The address of the session key from which the permission was removed
    /// @param wallet The address of the wallet associated with the session key
    /// @param indexToRemove The index of the permission to be removed
    event SKV_PermissionRemoved(
        address indexed sessionKey,
        address indexed wallet,
        uint256 indexToRemove
    );

    /// @notice Emitted when a permission is modified
    /// @param sessionKey The address of the session key
    /// @param wallet The address of the wallet
    /// @param index The index of the modified permission
    /// @param target The new target address
    /// @param selector The new function selector
    /// @param payableLimit The new call payable limit
    /// @param uses The new number of uses
    /// @param paramConditions The new parameter conditions
    event SKV_PermissionModified(
        address indexed sessionKey,
        address indexed wallet,
        uint256 index,
        address target,
        bytes4 selector,
        uint256 payableLimit,
        uint256 uses,
        ParamCondition[] paramConditions
    );

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Enables a session key
    /// @param _sessionData The session data
    /// @param _permissions The permissions to enable
    function enableSessionKey(
        SessionData memory _sessionData,
        Permission[] memory _permissions
    ) external;

    /// @notice Disables a session key
    /// @param _sessionKey The address of the session key to disable
    function disableSessionKey(address _sessionKey) external;

    /// @notice Rotates a session key
    /// @param _oldSessionKey The address of the old session key
    /// @param _newSessionData The new session data
    /// @param _newPermissions The new permissions to enable
    function rotateSessionKey(
        address _oldSessionKey,
        SessionData calldata _newSessionData,
        Permission[] calldata _newPermissions
    ) external;

    /// @notice Toggles the pause status of a session key
    /// @param _sessionKey The address of the session key to toggle
    function toggleSessionKeyPause(address _sessionKey) external;

    /// @notice Checks if a session key is live
    /// @param _sessionKey The address of the session key to check
    /// @return bool True if the session key is live, false otherwise
    function isSessionLive(address _sessionKey) external view returns (bool);

    /// @notice Gets the number of uses left for a session key
    /// @param _sessionKey The address of the session key
    /// @param _permissionIndex The index of the permission to check
    /// @return uint256 The number of uses left
    function getUsesLeft(
        address _sessionKey,
        uint256 _permissionIndex
    ) external view returns (uint256);

    /// @notice Updates the number of uses for a session key
    /// @param _sessionKey The address of the session key
    /// @param _permissionIndex The index of the permission to update
    /// @param _newUses The new number of uses
    function updateUses(
        address _sessionKey,
        uint256 _permissionIndex,
        uint256 _newUses
    ) external;

    /// @notice Updates the validUntil timestamp for a specific session key
    /// @dev Only the wallet owner can call this function
    /// @param _sessionKey The address of the session key to update
    /// @param _newValidUntil The new timestamp until which the session key will be valid
    /// @custom:throws SKV_SessionKeyDoesNotExist if the session key doesn't exist for the caller
    function updateValidUntil(
        address _sessionKey,
        uint48 _newValidUntil
    ) external;

    /// @notice Gets the associated session keys for the caller
    /// @return address[] An array of associated session key addresses
    function getSessionKeysByWallet() external view returns (address[] memory);

    /// @notice Gets the session key data for a specific session key
    /// @param _sessionKey The address of the session key
    /// @return SessionData The session data for the specified session key
    function getSessionKeyData(
        address _sessionKey
    ) external view returns (SessionData memory);

    /// @notice Gets the Permission data for a specific session key
    /// @param _sessionKey The address of the session key
    /// @return Permission[] The permission data for the specified session key
    function getSessionKeyPermissions(
        address _sessionKey
    ) external view returns (Permission[] memory);

    /// @notice Adds a new permission to a session key
    /// @dev This function appends a new permission to the end of the permissions array
    /// @param _sessionKey The address of the session key to modify
    /// @param _permission The permission to add
    function addPermission(
        address _sessionKey,
        Permission memory _permission
    ) external;

    /// @notice Removes a specific permission from a session key
    /// @dev This function shifts the remaining permissions to fill the gap and updates the permission count
    /// @param _sessionKey The address of the session key to modify
    /// @param _permissionIndex The index of the permission to remove
    function removePermission(
        address _sessionKey,
        uint256 _permissionIndex
    ) external;

    /// @notice Modifies an existing permission for a session key
    /// @param _sessionKey The address of the session key
    /// @param _index The index of the permission to modify
    /// @param _target The new target address
    /// @param _selector The new function selector
    /// @param _payableLimit The new payable limit
    /// @param _uses The new number of uses
    /// @param _paramConditions The new parameter conditions
    function modifyPermission(
        address _sessionKey,
        uint256 _index,
        address _target,
        bytes4 _selector,
        uint256 _uses,
        uint256 _payableLimit,
        ParamCondition[] calldata _paramConditions
    ) external;

    /// @notice Validates a user operation
    /// @param userOp The user operation to validate
    /// @param userOpHash The hash of the user operation
    /// @return uint256 The validation result
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256);

    /// @notice Checks if the module type matches the validator module type.
    /// @param moduleTypeId The module type ID to check.
    /// @return True if the module type matches the validator module type, false otherwise.
    function isModuleType(uint256 moduleTypeId) external pure returns (bool);

    /// @notice Placeholder function for module installation.
    /// @param data The data to pass during installation.
    function onInstall(bytes calldata data) external;

    /// @notice Placeholder function for module uninstallation.
    /// @param data The data to pass during uninstallation.
    function onUninstall(bytes calldata data) external;

    /// @notice Reverts with a "NotImplemented" error.
    /// @param sender The address of the sender.
    /// @param hash The hash of the message.
    /// @param data The data associated with the message.
    /// @return A bytes4 value indicating the function is not implemented.
    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4);

    /// @notice Reverts with a "NotImplemented" error.
    /// @param smartAccount The address of the smart account.
    /// @return True if the smart account is initialized, false otherwise.
    function isInitialized(address smartAccount) external view returns (bool);
}
