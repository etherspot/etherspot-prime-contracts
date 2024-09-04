// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IValidator} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {IERC7579Account} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";

/// @title TokenSessionKeyValidator Interface
/// @author Etherspot
/// @notice This interface defines the functions and events of the TokenSessionKeyValidator contract.
interface ITokenLockSessionKeyValidator is IValidator {
    /// @notice Emitted when the ERC20 Session Key Validator module is installed for a wallet.
    /// @param wallet The address of the wallet for which the module is installed.
    event TLSKV_ModuleInstalled(address wallet);

    /// @notice Emitted when the ERC20 Session Key Validator module is uninstalled from a wallet.
    /// @param wallet The address of the wallet from which the module is uninstalled.
    event TLSKV_ModuleUninstalled(address wallet);

    /// @notice Emitted when a new session key is enabled for a wallet.
    /// @param sessionKey The address of the session key.
    /// @param wallet The address of the wallet for which the session key is enabled.
    event TLSKV_SessionKeyEnabled(address sessionKey, address wallet);

    /// @notice Emitted when a session key is disabled for a wallet.
    /// @param sessionKey The address of the session key.
    /// @param wallet The address of the wallet for which the session key is disabled.
    event TLSKV_SessionKeyDisabled(address sessionKey, address wallet);

    /// @notice Emitted when a session key is paused for a wallet.
    /// @param sessionKey The address of the session key.
    /// @param wallet The address of the wallet for which the session key is paused.
    event TLSKV_SessionKeyPaused(address sessionKey, address wallet);

    /// @notice Emitted when a session key is unpaused for a wallet.
    /// @param sessionKey The address of the session key.
    /// @param wallet The address of the wallet for which the session key is unpaused.
    event TLSKV_SessionKeyUnpaused(address sessionKey, address wallet);

    /// @notice Struct representing the data associated with a session key.
    struct SessionData {
        address[] tokens; // The array of ERC20 token contract addresses.
        bytes4 funcSelector; // The function selector for the allowed operation (e.g., transfer, transferFrom).
        uint256[] amounts; // The array of lockedAmounts that has been locked for this session key.
        address solverAddress; // The address of the solver.
        uint48 validAfter; // The timestamp after which the session key is valid.
        uint48 validUntil; // The timestamp until which the session key is valid.
        bool live; // Flag indicating whether the session key is paused or not.
    }

    /// @notice Enables a new session key for the caller's wallet.
    /// @param _sessionData The encoded session data containing the session key address, token address, interface ID, function selector, spending limit, valid after timestamp, and valid until timestamp.
    function enableSessionKey(bytes calldata _sessionData) external;

    /// @notice Disables a session key for the caller's wallet.
    /// @param _session The address of the session key to disable.
    function disableSessionKey(address _session) external;

    /// @notice Rotates a session key by disabling the old one and enabling a new one.
    /// @param _oldSessionKey The address of the old session key to disable.
    /// @param _newSessionData The encoded session data for the new session key.
    function rotateSessionKey(
        address _oldSessionKey,
        bytes calldata _newSessionData
    ) external;

    /// @notice Toggles the pause state of a session key for the caller's wallet.
    /// @param _sessionKey The address of the session key to toggle the pause state for.
    function toggleSessionKeyPause(address _sessionKey) external;

    /// @notice Checks if a session key is paused for the caller's wallet.
    /// @param _sessionKey The address of the session key to check.
    /// @return paused True if the session key is paused, false otherwise.
    function isSessionKeyLive(
        address _sessionKey
    ) external view returns (bool paused);

    /// @notice Validates the parameters of a session key for a given user operation.
    /// @param _sessionKey The address of the session key.
    /// @param userOp The packed user operation containing the call data.
    /// @return True if the session key parameters are valid for the user operation, false otherwise.
    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) external returns (bool);

    /// @notice Returns the list of associated session keys for the caller's wallet.
    /// @return keys The array of associated session key addresses.
    function getAssociatedSessionKeys()
        external
        view
        returns (address[] memory keys);

    /// @notice Returns the session data for a given session key and the caller's wallet.
    /// @param _sessionKey The address of the session key.
    /// @return data The session data struct.
    function getSessionKeyData(
        address _sessionKey
    ) external view returns (SessionData memory data);

    /// @notice Validates a user operation using a session key.
    /// @param userOp The packed user operation.
    /// @param userOpHash The hash of the user operation.
    /// @return validationData The validation data containing the expiration time and valid after timestamp of the session key.
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256 validationData);

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
