// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "hardhat/console.sol";

abstract contract AccessController {
    uint128 immutable MULTIPLY_FACTOR = 1000;
    uint16 immutable SIXTY_PERCENT = 600;
    uint24 immutable INITIAL_PROPOSAL_TIMELOCK = 24 hours;

    uint256 public ownerCount;
    uint256 public guardianCount;
    uint256 public proposalId;
    uint256 public proposalTimelock;
    mapping(address => bool) private owners;
    mapping(address => bool) private guardians;
    mapping(uint256 => NewOwnerProposal) private proposals;

    struct NewOwnerProposal {
        address newOwnerProposed;
        bool resolved;
        uint256 approvalCount;
        address[] guardiansApproved;
        uint256 proposedAt;
    }

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

    modifier onlyOwner() {
        require(
            isOwner(msg.sender) || msg.sender == address(this),
            "ACL:: only owner"
        );
        _;
    }

    modifier onlyGuardian() {
        require(isGuardian(msg.sender), "ACL:: only guardian");
        _;
    }

    modifier onlyOwnerOrGuardian() {
        require(
            isOwner(msg.sender) ||
                msg.sender == address(this) ||
                isGuardian(msg.sender),
            "ACL:: only owner or guardian"
        );
        _;
    }

    modifier onlyOwnerOrEntryPoint(address _entryPoint) {
        require(
            msg.sender == _entryPoint ||
                msg.sender == address(this) ||
                isOwner(msg.sender),
            "ACL:: not owner or entryPoint"
        );
        _;
    }

    function isOwner(address _address) public view returns (bool) {
        return owners[_address];
    }

    function isGuardian(address _address) public view returns (bool) {
        return guardians[_address];
    }

    function addOwner(address _newOwner) external onlyOwner {
        _addOwner(_newOwner);
    }

    function removeOwner(address _owner) external onlyOwner {
        _removeOwner(_owner);
    }

    function addGuardian(address _newGuardian) external onlyOwner {
        _addGuardian(_newGuardian);
    }

    function removeGuardian(address _guardian) external onlyOwner {
        _removeGuardian(_guardian);
    }

    function changeProposalTimelock(uint256 _newTimelock) external onlyOwner {
        proposalTimelock = _newTimelock;
    }

    function getProposal(
        uint256 _proposalId
    )
        public
        view
        returns (
            address ownerProposed_,
            uint256 approvalCount_,
            address[] memory guardiansApproved_,
            bool resolved_,
            uint256 proposedAt_
        )
    {
        require(
            _proposalId != 0 && _proposalId <= proposalId,
            "ACL:: invalid proposal id"
        );
        NewOwnerProposal memory proposal = proposals[_proposalId];
        return (
            proposal.newOwnerProposed,
            proposal.approvalCount,
            proposal.guardiansApproved,
            proposal.resolved,
            proposal.proposedAt
        );
    }

    function discardCurrentProposal() external onlyOwnerOrGuardian {
        require(
            !proposals[proposalId].resolved,
            "ACL:: proposal already resolved"
        );
        if (isGuardian(msg.sender) && proposalTimelock > 0)
            require(
                (proposals[proposalId].proposedAt + proposalTimelock) <
                    block.timestamp,
                "ACL:: guardian cannot discard proposal until timelock relased"
            );
        if (isGuardian(msg.sender) && proposalTimelock == 0)
            require(
                (proposals[proposalId].proposedAt + INITIAL_PROPOSAL_TIMELOCK) <
                    block.timestamp,
                "ACL:: guardian cannot discard proposal until timelock relased"
            );
        proposals[proposalId].resolved = true;
        emit ProposalDiscarded(proposalId, msg.sender);
    }

    function guardianPropose(address _newOwner) external onlyGuardian {
        require(
            guardianCount >= 3,
            "ACL:: not enough guardians to propose new owner (minimum 3)"
        );
        if (
            proposals[proposalId].guardiansApproved.length != 0 &&
            proposals[proposalId].resolved == false
        ) revert("ACL:: latest proposal not yet resolved");

        proposalId = proposalId + 1;
        proposals[proposalId].newOwnerProposed = _newOwner;
        proposals[proposalId].guardiansApproved.push(msg.sender);
        proposals[proposalId].approvalCount += 1;
        proposals[proposalId].resolved = false;
        proposals[proposalId].proposedAt = block.timestamp;
        emit ProposalSubmitted(proposalId, _newOwner, msg.sender);
    }

    function guardianCosign(uint256 _proposalId) external onlyGuardian {
        require(
            _proposalId != 0 && _proposalId <= proposalId,
            "ACL:: invalid proposal id"
        );
        require(
            !_checkIfSigned(_proposalId),
            "ACL:: guardian already signed proposal"
        );
        require(
            !proposals[proposalId].resolved,
            "ACL:: proposal already resolved"
        );
        proposals[_proposalId].guardiansApproved.push(msg.sender);
        proposals[_proposalId].approvalCount += 1;
        address newOwner = proposals[_proposalId].newOwnerProposed;
        if (_checkQuorumReached(_proposalId)) {
            proposals[proposalId].resolved = true;
            _addOwner(newOwner);
        } else {
            emit QuorumNotReached(
                _proposalId,
                newOwner,
                proposals[_proposalId].approvalCount
            );
        }
    }

    // INTERNAL

    function _addOwner(address _newOwner) internal {
        // no check for address(0) as used when creating wallet via BLS.
        require(_newOwner != address(0), "ACL:: zero address");
        require(!owners[_newOwner], "ACL:: already owner");
        if (isGuardian(_newOwner)) revert("ACL:: guardian cannot be owner");
        emit OwnerAdded(_newOwner);
        owners[_newOwner] = true;
        ownerCount = ownerCount + 1;
    }

    function _addGuardian(address _newGuardian) internal {
        require(_newGuardian != address(0), "ACL:: zero address");
        require(!guardians[_newGuardian], "ACL:: already guardian");
        require(!isOwner(_newGuardian), "ACL:: guardian cannot be owner");
        emit GuardianAdded(_newGuardian);
        guardians[_newGuardian] = true;
        guardianCount = guardianCount + 1;
    }

    function _removeOwner(address _owner) internal {
        require(owners[_owner], "ACL:: non-existant owner");
        require(ownerCount > 1, "ACL:: wallet cannot be ownerless");
        emit OwnerRemoved(_owner);
        owners[_owner] = false;
        ownerCount = ownerCount - 1;
    }

    function _removeGuardian(address _guardian) internal {
        require(guardians[_guardian], "ACL:: non-existant guardian");
        emit GuardianRemoved(_guardian);
        guardians[_guardian] = false;
        guardianCount = guardianCount - 1;
    }

    function _checkIfSigned(uint256 _proposalId) internal view returns (bool) {
        for (uint i; i < proposals[_proposalId].guardiansApproved.length; i++) {
            if (proposals[_proposalId].guardiansApproved[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function _checkQuorumReached(
        uint256 _proposalId
    ) internal view returns (bool) {
        return ((proposals[_proposalId].approvalCount * MULTIPLY_FACTOR) /
            guardianCount >=
            SIXTY_PERCENT);
    }
}
