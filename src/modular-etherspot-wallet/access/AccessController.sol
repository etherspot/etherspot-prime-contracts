// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAccessController} from "../interfaces/IAccessController.sol";
import {ErrorsLib} from "../libraries/ErrorsLib.sol";

contract AccessController is IAccessController {
    /// State Variables
    uint128 constant MULTIPLY_FACTOR = 1000;
    uint16 constant SIXTY_PERCENT = 600;
    uint24 constant INITIAL_PROPOSAL_TIMELOCK = 24 hours;
    uint256 public ownerCount;
    uint256 public guardianCount;
    uint256 public proposalId;
    uint256 public proposalTimelock;

    /// Mappings
    mapping(address => bool) private _owners;
    mapping(address => bool) private _guardians;
    mapping(uint256 => NewOwnerProposal) private _proposals;

    /// Modifiers
    modifier onlyOwnerOrSelf() {
        if (!(isOwner(msg.sender) || msg.sender == address(this))) {
            revert ErrorsLib.OnlyOwnerOrSelf();
        }
        _;
    }

    modifier onlyGuardian() {
        if (!isGuardian(msg.sender)) {
            revert ErrorsLib.OnlyGuardian();
        }
        _;
    }

    modifier onlyOwnerOrGuardianOrSelf() {
        if (
            !(isOwner(msg.sender) ||
                isGuardian(msg.sender) ||
                msg.sender == address(this))
        ) {
            revert ErrorsLib.OnlyOwnerOrGuardianOrSelf();
        }
        _;
    }

    /// External
    /**
     * @notice Add owner to the wallet.
     * @dev Only owner or wallet.
     * @param _newOwner address of new owner to add.
     */
    function addOwner(address _newOwner) external onlyOwnerOrSelf {
        if (
            _newOwner == address(0) ||
            isGuardian(_newOwner) ||
            isOwner(_newOwner)
        ) {
            revert ErrorsLib.AddingInvalidOwner();
        }
        _addOwner(_newOwner);
        emit OwnerAdded(address(this), _newOwner);
    }

    /**
     * @notice Remove owner from wallet.
     * @dev Only owner or wallet.
     * @param _owner address of wallet owner to remove .
     */
    function removeOwner(address _owner) external onlyOwnerOrSelf {
        if (!isOwner(_owner)) revert ErrorsLib.RemovingInvalidOwner();
        if (ownerCount <= 1) {
            revert ErrorsLib.WalletNeedsOwner();
        }
        _removeOwner(_owner);
        emit OwnerRemoved(address(this), _owner);
    }

    /**
     * @notice Add guardian for the wallet.
     * @dev Only owner or wallet.
     * @param _newGuardian address of new guardian to add to wallet.
     */
    function addGuardian(address _newGuardian) external onlyOwnerOrSelf {
        if (
            _newGuardian == address(0) ||
            isGuardian(_newGuardian) ||
            isOwner(_newGuardian)
        ) {
            revert ErrorsLib.AddingInvalidGuardian();
        }
        _addGuardian(_newGuardian);
        emit GuardianAdded(address(this), _newGuardian);
    }

    /**
     * @notice Remove guardian from the wallet.
     * @dev Only owner or wallet.
     * @param _guardian address of existing guardian to remove.
     */
    function removeGuardian(address _guardian) external onlyOwnerOrSelf {
        if (!isGuardian(_guardian)) revert ErrorsLib.RemovingInvalidGuardian();
        _removeGuardian(_guardian);
        emit GuardianRemoved(address(this), _guardian);
    }

    /**
     * @notice Change the timelock on proposals.
     * The minimum time (secs) that a proposal is allowed to be discarded.
     * @dev Only owner or wallet.
     * @param   _newTimelock new timelock in seconds.
     */
    function changeProposalTimelock(
        uint256 _newTimelock
    ) external onlyOwnerOrSelf {
        assembly {
            sstore(proposalTimelock.slot, _newTimelock)
        }
    }

    /**
     * @notice Discards the current proposal.
     * @dev Only owner or guardian or wallet. Must be after the proposal timelock is met.
     */
    function discardCurrentProposal() public onlyOwnerOrGuardianOrSelf {
        NewOwnerProposal storage prop = _proposals[proposalId];
        uint256 timelock = proposalTimelock == 0
            ? INITIAL_PROPOSAL_TIMELOCK
            : proposalTimelock;
        if (_resolvedProposal()) {
            revert ErrorsLib.ProposalResolved();
        }
        bool allowed = isGuardian(msg.sender);
        if (allowed && (prop.proposedAt + timelock >= block.timestamp))
            revert ErrorsLib.ProposalTimelocked();

        prop.resolved = true;
        emit ProposalDiscarded(address(this), proposalId, msg.sender);
    }

    /**
     * @notice Creates a new owner proposal (adds new owner to wallet).
     * @dev Only guardian.
     * @param _newOwner the proposed new owner for the wallet.
     */
    function guardianPropose(address _newOwner) external onlyGuardian {
        if (
            _newOwner == address(0) ||
            isGuardian(_newOwner) ||
            isOwner(_newOwner)
        ) {
            revert ErrorsLib.AddingInvalidOwner();
        }
        if (guardianCount < 3) {
            revert ErrorsLib.NotEnoughGuardians();
        }
        NewOwnerProposal storage prop = _proposals[proposalId];
        if (prop.guardiansApproved.length != 0 && !prop.resolved) {
            revert ErrorsLib.ProposalUnresolved();
        }
        uint256 newProposalId = proposalId + 1;
        _proposals[newProposalId].newOwnerProposed = _newOwner;
        _proposals[newProposalId].guardiansApproved.push(msg.sender);
        _proposals[newProposalId].approvalCount++;
        _proposals[newProposalId].resolved = false;
        _proposals[newProposalId].proposedAt = block.timestamp;
        proposalId = newProposalId;
        emit ProposalSubmitted(
            address(this),
            newProposalId,
            _newOwner,
            msg.sender
        );
    }

    /**
     * @notice Cosigns a new owner proposal.
     * @dev Only guardian. Must meet minimum threshold of 60% of total guardians to add new owner.
     */
    function guardianCosign() external onlyGuardian {
        uint256 latestId = proposalId;
        NewOwnerProposal storage latestProp = _proposals[latestId];
        if (latestId == 0) {
            revert ErrorsLib.InvalidProposal();
        }
        if (_checkIfSigned(latestId)) {
            revert ErrorsLib.AlreadySignedProposal();
        }
        if (_resolvedProposal()) {
            revert ErrorsLib.ProposalResolved();
        }
        _proposals[latestId].guardiansApproved.push(msg.sender);
        _proposals[latestId].approvalCount++;
        address newOwner = latestProp.newOwnerProposed;
        if (_checkQuorumReached(latestId)) {
            _proposals[latestId].resolved = true;
            _addOwner(newOwner);
        } else {
            emit QuorumNotReached(
                address(this),
                latestId,
                newOwner,
                _proposals[latestId].approvalCount
            );
        }
    }

    /// Views
    /**
     * @notice Checks if _address is owner of wallet.
     * @param _address address to check if owner of wallet.
     * @return  bool.
     */
    function isOwner(address _address) public view returns (bool) {
        return _owners[_address];
    }

    /**
     * @notice Checks if _address is guardian of wallet.
     * @param _address address to check if guardian of wallet.
     * @return  bool.
     */
    function isGuardian(address _address) public view returns (bool) {
        return _guardians[_address];
    }

    /**
     * @notice Returns new owner proposal data.
     * @param _proposalId proposal id to return data for.
     * @return ownerProposed_ the new owner proposed.
     * @return approvalCount_ number of guardians that have approved the proposal.
     * @return guardiansApproved_ array of guardian addresses that have approved proposal.
     * @return resolved_ bool is the proposal resolved.
     * @return proposedAt_ timestamp of when proposal was initiated.
     */
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
        if (_proposalId == 0 || _proposalId > proposalId) {
            revert ErrorsLib.InvalidProposal();
        }
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
        ownerCount++;
    }

    function _addGuardian(address _newGuardian) internal {
        _guardians[_newGuardian] = true;
        guardianCount++;
        if (!_resolvedProposal()) discardCurrentProposal();
    }

    function _removeOwner(address _owner) internal {
        _owners[_owner] = false;
        ownerCount--;
    }

    function _removeGuardian(address _guardian) internal {
        _guardians[_guardian] = false;
        guardianCount--;
        if (!_resolvedProposal()) discardCurrentProposal();
    }

    function _checkIfSigned(uint256 _proposalId) internal view returns (bool) {
        for (
            uint256 i;
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

    function _resolvedProposal() internal view returns (bool) {
        NewOwnerProposal storage prop = _proposals[proposalId];
        return prop.resolved;
    }
}
