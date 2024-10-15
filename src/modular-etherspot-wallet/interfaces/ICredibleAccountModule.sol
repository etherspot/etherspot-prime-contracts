// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IValidator, IHook} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {IERC7579Account} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SessionData, TokenData} from "../common/Structs.sol";

/// @title CredibleAccountModule Interface
/// @author Etherspot
/// @notice This interface defines the functions and events of the CredibleAccountModule contract.
interface ICredibleAccountModule is IValidator, IHook {
    /*//////////////////////////////////////////////////////////////
                            STRUCTS/ENUMS
    //////////////////////////////////////////////////////////////*/

    struct Initialization {
        bool validatorInitialized;
        bool hookInitialized;
    }

    /// @notice Struct representing the data associated with a session key.
    struct LockedToken {
        address token;
        uint256 lockedAmount;
        uint256 claimedAmount;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the ERC20 Session Key Validator module is installed for a wallet.
    /// @param wallet The address of the wallet for which the module is installed.
    event CredibleAccountModule_ModuleInstalled(address wallet);

    /// @notice Emitted when the ERC20 Session Key Validator module is uninstalled from a wallet.
    /// @param wallet The address of the wallet from which the module is uninstalled.
    event CredibleAccountModule_ModuleUninstalled(address wallet);

    /// @notice Emitted when a new session key is enabled for a wallet.
    /// @param sessionKey The address of the session key.
    /// @param wallet The address of the wallet for which the session key is enabled.
    event CredibleAccountModule_SessionKeyEnabled(
        address indexed sessionKey,
        address indexed wallet
    );

    /// @notice Emitted when a session key is disabled for a wallet.
    /// @param sessionKey The address of the session key.
    /// @param wallet The address of the wallet for which the session key is disabled.
    event CredibleAccountModule_SessionKeyDisabled(
        address sessionKey,
        address wallet
    );

    /// @notice Emitted when a session key is paused for a wallet.
    /// @param sessionKey The address of the session key.
    /// @param wallet The address of the wallet for which the session key is paused.
    event CredibleAccountModule_SessionKeyPaused(
        address sessionKey,
        address wallet
    );

    /// @notice Emitted when a session key is unpaused for a wallet.
    /// @param sessionKey The address of the session key.
    /// @param wallet The address of the wallet for which the session key is unpaused.
    event CredibleAccountModule_SessionKeyUnpaused(
        address sessionKey,
        address wallet
    );

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Enables a new session key for the caller's wallet.
    /// @param _sessionData The encoded session data containing the session key address, token address, interface ID, function selector, spending limit, valid after timestamp, and valid until timestamp.
    function enableSessionKey(bytes calldata _sessionData) external;

    /// @notice Disables a session key for the caller's wallet.
    /// @param _session The address of the session key to disable.
    function disableSessionKey(address _session) external;

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
    function getSessionKeysByWallet()
        external
        view
        returns (address[] memory keys);

    /// @notice Returns the list of associated session keys for the provided wallet.
    /// @return keys The array of associated session key addresses.
    function getSessionKeysByWallet(
        address _wallet
    ) external view returns (address[] memory keys);

    /// @notice Returns the session data for a given session key and the caller's wallet.
    /// @param _sessionKey The address of the session key.
    /// @return data The session data struct.
    function getSessionKeyData(
        address _sessionKey
    ) external view returns (SessionData memory data);

    /// @notice Retrieves all locked tokens for a specific session key
    /// @param _sessionKey The address of the session key to query
    /// @return An array of LockedToken structs associated with the given session key
    function getLockedTokensForSessionKey(
        address _sessionKey
    ) external view returns (LockedToken[] memory);

    /// @notice Retrieves the total locked amount for a specific token across all session keys for the calling wallet
    /// @param _token The address of the token to check
    /// @return The total locked amount of the specified token
    function tokenTotalLockedForWallet(
        address _token
    ) external view returns (uint256);

    /// @notice Retrieves the cumulative locked amounts for all unique tokens across all session keys for the calling wallet
    /// @return An array of TokenData structures containing token addresses and their corresponding locked amounts
    function cumulativeLockedForWallet()
        external
        view
        returns (TokenData[] memory);

    /// @notice Checks if all tokens for a given session key have been claimed
    /// @dev Iterates through all locked tokens for the session key
    /// @param _sessionKey The address of the session key to check
    /// @return bool True if all tokens are claimed, false otherwise
    function isSessionClaimed(address _sessionKey) external view returns (bool);

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

    /// @notice Performs pre-execution checks and prepares hook data
    /// @dev This function is called before the main execution
    /// @param msgSender The address initiating the transaction
    /// @param msgValue The amount of Ether sent with the transaction
    /// @param msgData The calldata of the transaction
    /// @return hookData Encoded data to be used in post-execution checks
    function preCheck(
        address msgSender,
        uint256 msgValue,
        bytes calldata msgData
    ) external returns (bytes memory hookData);

    /// @notice Performs post-execution checks using the hook data
    /// @dev This function is called after the main execution
    /// @param hookData The data prepared by preCheck function
    function postCheck(bytes calldata hookData) external;
}
