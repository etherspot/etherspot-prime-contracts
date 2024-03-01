// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IAccessController {
    /// Structs
    struct NewOwnerProposal {
        address newOwnerProposed;
        bool resolved;
        address[] guardiansApproved;
        uint256 approvalCount;
        uint256 proposedAt;
    }

    /// Events
    event OwnerAdded(address account, address newOwner);
    event OwnerRemoved(address account, address removedOwner);
    event GuardianAdded(address account, address newGuardian);
    event GuardianRemoved(address account, address removedGuardian);
    event ProposalSubmitted(
        address account,
        uint256 proposalId,
        address newOwnerProposed,
        address proposer
    );
    event QuorumNotReached(
        address account,
        uint256 proposalId,
        address newOwnerProposed,
        uint256 approvalCount
    );
    event ProposalDiscarded(
        address account,
        uint256 proposalId,
        address discardedBy
    );

    /// External
    function addOwner(address _newOwner) external;

    function removeOwner(address _owner) external;

    function addGuardian(address _newGuardian) external;

    function removeGuardian(address _guardian) external;

    function changeProposalTimelock(uint256 _newTimelock) external;

    function discardCurrentProposal() external;

    function guardianPropose(address _newOwner) external;

    function guardianCosign() external;

    /// Views
    function isOwner(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function getProposal(
        uint256 _proposalId
    )
        external
        view
        returns (
            address ownerProposed_,
            uint256 approvalCount_,
            address[] memory guardiansApproved_,
            bool resolved_,
            uint256 proposedAt_
        );
}
