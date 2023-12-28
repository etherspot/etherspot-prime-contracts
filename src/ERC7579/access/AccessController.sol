// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ErrorsLib} from "../libraries/ErrorsLib.sol";

contract AccessController {
    /// State Variables
    string public constant NAME = "Access Controller";
    string public constant VERSION = "1.0.0";
    string public constant AUTHOR = "Etherspot";
    uint128 immutable MULTIPLY_FACTOR = 1000;
    uint16 immutable SIXTY_PERCENT = 600;
    uint24 immutable INITIAL_PROPOSAL_TIMELOCK = 24 hours;
    uint256 public ownerCount;
    uint256 public guardianCount;
    uint256 public proposalId;
    uint256 public proposalTimelock;

    /// Mappings
    mapping(address => bool) private _owners;
    mapping(address => bool) private _guardians;
    mapping(uint256 => NewOwnerProposal) private _proposals;

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
    event ProposalTimelockChanged(address account, uint256 newTimelock);

    /// Modifiers
    modifier onlyOwnerOrSelf() {
        if (!isOwner(msg.sender) || msg.sender != address(this))
            revert ErrorsLib.OnlyOwnerOrSelf();
        _;
    }

    modifier onlyGuardian() {
        if (!isGuardian(msg.sender)) revert ErrorsLib.OnlyGuardian();
        _;
    }

    modifier onlyOwnerOrGuardianOrSelf() {
        if (
            !isOwner(msg.sender) ||
            !isGuardian(msg.sender) ||
            msg.sender != address(this)
        ) revert ErrorsLib.OnlyOwnerOrGuardianOrSelf();
        _;
    }

    /// External
    function addOwner(address _newOwner) external onlyGuardian {
        if (
            _newOwner == address(0) ||
            isGuardian(_newOwner) ||
            isOwner(_newOwner)
        ) revert ErrorsLib.AddingInvalidOwner();
        _addOwner(_newOwner);
        emit OwnerAdded(msg.sender, _newOwner);
    }

    function removeOwner(address _owner) external onlyGuardian {
        if (_owner == address(0) || !isOwner(_owner))
            revert ErrorsLib.RemovingInvalidOwner();
        if (ownerCount <= 1) revert ErrorsLib.WalletNeedsOwner();
        _removeOwner(_owner);
        emit OwnerRemoved(msg.sender, _owner);
    }

    function addGuardian(address _newGuardian) external onlyOwnerOrSelf {
        if (
            _newGuardian == address(0) ||
            isGuardian(_newGuardian) ||
            isOwner(_newGuardian)
        ) revert ErrorsLib.AddingInvalidGuardian();
        _addGuardian(_newGuardian);
        emit GuardianAdded(msg.sender, _newGuardian);
    }

    function removeGuardian(address _guardian) external onlyOwnerOrSelf {
        if (_guardian == address(0) || !isGuardian(_guardian))
            revert ErrorsLib.RemovingInvalidGuardian();
        _removeGuardian(_guardian);
        emit GuardianRemoved(msg.sender, _guardian);
    }

    function changeProposalTimelock(
        uint256 _newTimelock
    ) external onlyOwnerOrSelf {
        proposalTimelock = _newTimelock;
        emit ProposalTimelockChanged(msg.sender, _newTimelock);
    }

    function discardCurrentProposal() external onlyOwnerOrGuardianOrSelf {
        if (_proposals[proposalId].resolved)
            revert ErrorsLib.ProposalResolved();
        if (isGuardian(msg.sender) && proposalTimelock > 0) {
            if (
                (_proposals[proposalId].proposedAt + proposalTimelock) >=
                block.timestamp
            ) revert ErrorsLib.ProposalTimelocked();
        }
        if (isGuardian(msg.sender) && proposalTimelock == 0) {
            if (
                (_proposals[proposalId].proposedAt +
                    INITIAL_PROPOSAL_TIMELOCK) >= block.timestamp
            ) revert ErrorsLib.ProposalTimelocked();
        }
        _proposals[proposalId].resolved = true;
        emit ProposalDiscarded(msg.sender, proposalId, msg.sender);
    }

    function guardianPropose(address _newOwner) external onlyGuardian {
        if (guardianCount < 3) revert ErrorsLib.NotEnoughGuardians();
        if (
            _proposals[proposalId].guardiansApproved.length != 0 &&
            _proposals[proposalId].resolved == false
        ) revert ErrorsLib.ProposalUnresolved();

        proposalId = proposalId + 1;
        _proposals[proposalId].newOwnerProposed = _newOwner;
        _proposals[proposalId].guardiansApproved.push(msg.sender);
        _proposals[proposalId].approvalCount += 1;
        _proposals[proposalId].resolved = false;
        _proposals[proposalId].proposedAt = block.timestamp;
        emit ProposalSubmitted(msg.sender, proposalId, _newOwner, msg.sender);
    }

    function guardianCosign() external onlyGuardian {
        if (proposalId == 0) revert ErrorsLib.InvalidProposalId();
        if (_checkIfSigned(proposalId))
            revert ErrorsLib.AlreadySignedProposal();
        if (_proposals[proposalId].resolved)
            revert ErrorsLib.ProposalResolved();
        _proposals[proposalId].guardiansApproved.push(msg.sender);
        _proposals[proposalId].approvalCount += 1;
        address newOwner = _proposals[proposalId].newOwnerProposed;
        if (_checkQuorumReached(proposalId)) {
            _proposals[proposalId].resolved = true;
            _addOwner(newOwner);
        } else {
            emit QuorumNotReached(
                msg.sender,
                proposalId,
                newOwner,
                _proposals[proposalId].approvalCount
            );
        }
    }

    /// Views
    function isOwner(address _address) public view returns (bool) {
        return _owners[_address];
    }

    function isGuardian(address _address) public view returns (bool) {
        return _guardians[_address];
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
        if (_proposalId == 0 && _proposalId > proposalId)
            revert ErrorsLib.InvalidProposalId();
        NewOwnerProposal memory proposal = _proposals[_proposalId];
        return (
            proposal.newOwnerProposed,
            proposal.approvalCount,
            proposal.guardiansApproved,
            proposal.resolved,
            proposal.proposedAt
        );
    }

    /// Internal
    function _addOwner(address _newOwner) internal {
        _owners[_newOwner] = true;
        ownerCount = ownerCount + 1;
    }

    function _addGuardian(address _newGuardian) internal {
        _guardians[_newGuardian] = true;
        guardianCount = guardianCount + 1;
    }

    function _removeOwner(address _owner) internal {
        _owners[_owner] = false;
        ownerCount = ownerCount - 1;
    }

    function _removeGuardian(address _guardian) internal {
        _guardians[_guardian] = false;
        guardianCount = guardianCount - 1;
    }

    function _checkIfSigned(uint256 _proposalId) internal view returns (bool) {
        for (
            uint i;
            i < _proposals[_proposalId].guardiansApproved.length;
            i++
        ) {
            if (_proposals[_proposalId].guardiansApproved[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function _checkQuorumReached(
        uint256 _proposalId
    ) internal view returns (bool) {
        return ((_proposals[_proposalId].approvalCount * MULTIPLY_FACTOR) /
            guardianCount >=
            SIXTY_PERCENT);
    }
}
