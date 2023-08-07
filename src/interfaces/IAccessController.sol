// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IAccessController {
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address removedOwner);
    event GuardianAdded(address newGuardian);
    event GuardianRemoved(address removedGuardian);
    event ProposalSubmitted(
        uint256 proposalId,
        address newOwnerProposed,
        address proposer
    );
    event QuorumNotReached(
        uint256 proposalId,
        address newOwnerProposed,
        uint256 approvalCount
    );
    event ProposalDiscarded(uint256 proposalId, address discardedBy);

    function isOwner(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function addOwner(address _newOwner) external;

    function removeOwner(address _owner) external;

    function addGuardian(address _newGuardian) external;

    function removeGuardian(address _guardian) external;

    function changeProposalTimelock(uint256 _newTimelock) external;

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

    function discardCurrentProposal() external;

    function guardianPropose(address _newOwner) external;

    function guardianCosign() external;
}
