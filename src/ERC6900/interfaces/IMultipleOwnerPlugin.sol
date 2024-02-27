// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UserOperation} from "../../../account-abstraction/contracts/interfaces/UserOperation.sol";

interface IMultipleOwnerPlugin {
    enum FunctionId {
        RUNTIME_VALIDATION_OWNER_OR_SELF,
        USER_OP_VALIDATION_OWNER
    }

    /// @notice This event is emitted when ownership of the account changes.
    /// @param account The account whose ownership changed.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(
        address indexed account,
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice This event is emitted when a new owner is added for a wallet.
    /// @param account The account whose ownership changed.
    /// @param added The address of the new owner.
    event OwnerAdded(address account, address added);

    /// @notice This event is emitted when an owner is removed from a wallet.
    /// @param account The account whose ownership changed.
    /// @param removed The address of the removed owner.
    event OwnerRemoved(address account, address removed);

    /// @notice Transfer ownership of the account from `_currentOwner` to `_newOwner`.
    /// @dev This function is installed on the account as part of plugin installation, and should
    /// only be called from an account.
    /// @param _newOwner The address of the new owner.
    function transferOwnership(address _newOwner) external;

    /// @notice Get the owners of the `account`.
    /// @dev This function is installed on the account as part of plugin installation, and should
    /// only be called from an account.
    /// @return The addresses of the owners.
    function owners() external view returns (address[] memory);

    /// @notice Get the owners of `account`.
    /// @dev This function is not installed on the account, and can be called by anyone.
    /// @param account The account to get the owner of.
    /// @return The addresses of the owners.
    function ownersOf(address account) external view returns (address[] memory);

    /// @notice Checks if address is an owner of the account.
    /// @dev This function is installed on the account as part of plugin installation, and should
    /// only be called from an account.
    /// @param _owner The address to check if owner of account.
    /// @return True if owner, false if not owner.
    function isOwner(address _owner) external view returns (bool);

    /// @notice Checks if address is an owner of the `account`.
    /// @dev This function is not installed on the account, and can be called by anyone.
    /// @param _account The account to check the owner of.
    /// @param _owner The address to check if owner of account.
    /// @return True if owner, false if not owner.
    function isOwnerOfAccount(
        address _account,
        address _owner
    ) external view returns (bool);

    /// @notice Adds a new owner to the account.
    /// @dev This function is installed on the account as part of plugin installation, and should
    /// only be called from an account.
    /// @param _account The address of the account.
    /// @param _newOwner The address to add as a new owner of the account.
    function addOwner(address _account, address _newOwner) external;

    /// @notice Removes an owner from the account.
    /// @dev This function is installed on the account as part of plugin installation, and should
    /// only be called from an account.
    /// @param _account The address of the account.
    /// @param _owner The address to remove as an owner of the account.
    function removeOwner(address _account, address _owner) external;
}
