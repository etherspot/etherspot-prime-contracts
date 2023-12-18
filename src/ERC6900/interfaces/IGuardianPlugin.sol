// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UserOperation} from "@ERC4337/interfaces/UserOperation.sol";

interface IGuardianPlugin {
    enum FunctionId {
        RUNTIME_VALIDATION_OWNER_OR_GUARDIAN_OR_SELF,
        RUNTIME_VALIDATION_GUARDIAN,
        USER_OP_VALIDATION_GUARDIAN
    }

    /// @notice This event is emitted when a guardian is added to an account.
    /// @param account The account whose guardianship changed.
    /// @param guardianAdded The address of the new guardian.
    event GuardianAdded(address account, address guardianAdded);

    /// @notice This event is emitted when a guardian is removed from an account.
    /// @param account The account whose guardianship changed.
    /// @param removedGuardian The address of the removed guardian.
    event GuardianRemoved(address account, address removedGuardian);

    /// @notice This event is emitted when the proposal timelock on an account is changed.
    /// @param account The account whose proposal timelock changed.
    /// @param newProposalTimelock The new proposal timelock.
    event ProposalTimelockChanged(address account, uint256 newProposalTimelock);

    /// @notice This event is emitted when the latest new owner proposal is discarded.
    /// @param account The account whose proposal has been discarded.
    /// @param proposalId The id of the discarded proposal.
    event ProposalDiscarded(address account, uint256 proposalId);

    /// @notice This event is emitted when the latest new owner proposal is discarded.
    /// @param account The account with the new owner proposal.
    /// @param proposalId The id of the new proposal.
    /// @param newOwnerProposed The new owner proposed for account.
    event GuardianProposalSubmitted(
        address account,
        uint256 proposalId,
        address newOwnerProposed
    );

    /// @notice This event is emitted when the latest new owner proposal is discarded.
    /// @param account The account with the new owner proposal.
    /// @param proposalId The id of the new proposal.
    /// @param newOwnerProposed The new owner proposed for account.
    /// @param approvalCount The number of account guardians that have approved the proposal.
    event QuorumNotReached(
        address account,
        uint256 proposalId,
        address newOwnerProposed,
        uint256 approvalCount
    );

    /// @notice Adds a guardian to the `account`.
    /// @dev Should only be called from an account.
    /// _newGuardian has to not be existing guardian on the account and cannot be an owner.
    /// @param _newGuardian Address of the new guardian to be added.
    function addGuardian(address _newGuardian) external;

    /// @notice Removes a guardian from the `account`.
    /// @dev Should only be called from an account.
    /// _guardian has to be existing guardian on the account.
    /// @param _guardian Address of the guardian to be removed.
    function removeGuardian(address _guardian) external;

    /// @notice Changes the proposal timelock on the `account`.
    /// @dev Should only be called from an account.
    /// @param _newTimelock New proposal timelock to be applied.
    function changeProposalTimelock(uint256 _newTimelock) external;

    /// @notice Discards the current new owner proposal for the `account`.
    /// @dev Should only be called from an account or by an owner or guardian.
    /// @param _account Account to discard current proposal for.
    function discardCurrentProposal(address _account) external;

    /// @notice Creates a new owner proposal for the `account`.
    /// @dev Should only be called by account guardian.
    /// @param _account Account to create a new owner proposal for.
    /// @param _newOwner Address of the new owner to be proposed.
    function guardianPropose(address _account, address _newOwner) external;

    /// @notice Co-signs a new owner proposal for the `account`.
    /// @dev Should only be called by account guardian.
    /// Cannot be co-signed by guardian that has either proposed it or already co-signed.
    /// @param _account Account to co-sign the latest new owner proposal for.
    function guardianCosign(address _account) external;

    /// @notice Checks if address is guardian of the `account`.
    /// @dev Should only be called from an account.
    /// @param _guardian Address to check guardianship.
    /// @return boolean
    function isGuardian(address _guardian) external view returns (bool);

    /// @notice Checks if address is guardian of the `account`.
    /// @param _account Account to check guardianship.
    /// @param _guardian Address to check guardianship.
    /// @return boolean
    function isGuardianOfAccount(
        address _account,
        address _guardian
    ) external view returns (bool);

    /// @notice Gets owners of `account`.
    /// @param _account Account to check ownership.
    /// @return Array of current owners for the `account`.
    function getOwnersForAccount(
        address _account
    ) external returns (address[] memory);

    /// @notice Gets the information of a new owner proposal for the `account`.
    /// @param _account Account to check new owner proposal of.
    /// @param _proposalId Proposal id to return information for.
    /// @return newOwnerProposed address of the proposed new owner,
    /// resolved boolean to show if proposal has been resolved (passed, in process or discarded),
    /// approvalCount number of guardians that have co-signed the proposal,
    /// guardiansApproved array of addresses showing co-signed guardians,
    /// proposedAt time that the new owner proposal was created (for use with timelock).
    function getProposal(
        address _account,
        uint256 _proposalId
    )
        external
        view
        returns (
            address newOwnerProposed,
            bool resolved,
            uint256 approvalCount,
            address[] memory guardiansApproved,
            uint256 proposedAt
        );

    /// @notice Gets the number of guardians an `account` has.
    /// @param _account Account to check.
    /// @return Number of guardians on the `account`.
    function getAccountGuardianCount(
        address _account
    ) external view returns (uint256);

    /// @notice Gets the current proposal id for the `account`.
    /// @param _account Account to check.
    /// @return Current proposal id for `account`.
    function getAccountCurrentProposalId(
        address _account
    ) external view returns (uint256);

    /// @notice Gets the current proposal timelock for the `account`.
    /// @dev Will return either the default proposal timelock or custom one if set.
    /// @param _account Account to check.
    /// @return Current proposal timelock for `account`.
    function getAccountProposalTimelock(
        address _account
    ) external view returns (uint256);
}
