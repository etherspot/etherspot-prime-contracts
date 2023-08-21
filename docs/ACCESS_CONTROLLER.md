# AccessController.sol

## Overview

The `AccessController` abstract contract is a simple implementation that allows for wallet ownership/guardianship. It provides the functionality to check if an address is a owner or guardian, add a new owner an guardian, or remove an existing owner and guardian. It contains modifiers that check for ownership, guardianship and calls from `EntryPoint`. In it's current iteration it is designed to be used with `EtherspotWallet` to allow for wallets to have multiple owners and guardians.  

## Version

Solidity pragma version `^0.8.12`.  

## State Variables

- `MULTIPLY_FACTOR`: immutable value of `1000` for calculation of percentages.
- `SIXTY_PERCENT`: immutable value of `600` for calculation of percentages.
- `INITIAL_PROPOSAL_TIMELOCK`: immutable value of `24 hours` as a default proposal timelock period;
- `ownerCount`: public value, tracks count of how many owners a wallet has.
- `guardianCount`: public value, tracks count of how many guardians a wallet has.
- `proposalId`: public value, tracks proposal ids for guardians adding new owners.

## Structs

- `NewOwnerProposal`: stores the following data for guardians proposing new owners:
  - `newOwnerProposed`: address of the new owner that a guardian is proposing to add.
  - `approvalCount`: how many guardians have approved this proposal (quorum required 60% of total guardians).
  - `guardiansApproved`: array of the guardian addresses that have approved this proposal.
  - `resolved`: boolean to indicate whether the proposal has been actioned or discarded.
  - `proposedAt`: timestamp of when the proposal was submitted.

## Modifiers

- `onlyOwner()`: check caller is an owner of the `EtherspotWallet` contract or `EtherspotWallet` contract itself.  
- `onlyGuardian()`: check caller is a guardian of the `EtherspotWallet` contract.
- `onlyOwnerOrGuardian()`: check caller is an owner of the `EtherspotWallet` contract, a guardian of the `EtherspotWallet` contract or `EtherspotWallet` contract itself.  
- `onlyOwnerOrEntryPoint()`: check caller is an owner of the `EtherspotWallet` contract, the `EntryPoint` contract or `EtherspotWallet` contract itself.  

## Mappings

- `mapping(address => bool) private owners`: A mapping of addresses to boolean values that indicate whether the address is an owner or not.  
- `mapping(address => bool) private guardians`: A mapping of addresses to boolean values that indicate whether the address is a guardian or not.  
- `mapping(uint256 => NewOwnerProposal) private proposals`: A mapping of proposal ids to NewOwnerProposals (see Structs).

## Events

- `event OwnerAdded(address newOwner)`: Triggered when a new guardian is added.  
- `event OwnerRemoved(address removedOwner)`: Triggered when a guardian is removed.  
- `event GuardianAdded(address newGuardian)`: Triggered when a new guardian is added.  
- `event GuardianRemoved(address removedGuardian)`: Triggered when a guardian is removed.
- `event ProposalSubmitted(uint256 proposalId, address newOwnerProposed, address proposer)`: Triggered when a guardian proposes a new owner to be added to `EtherspotWallet`.
- `event QuorumNotReached(uint256 proposalId, address newOwnerProposed, uint256 guardiansApproved)`: Triggered when a guardian cosigns a proposal to add a new owner to `EtherspotWallet` but the required quorum has not been reached (60% of total guardians).
- `event ProposalDiscarded(uint256 proposalId, address discardedBy)`: Triggered when a proposal will not be actioned and is discarded.

## Public/External Functions

- `function isOwner(address _address) public view returns (bool)`: Checks if an address is a owner or not.  
- `function isGuardian(address _address) public view returns (bool)`: Checks if an address is a guardian or not.  
- `function changeProposalTimelock(uint256 _newTimelock)`: Updates `proposalTimelock` variable which speficies the time after the proposal is made at which a guardian can discard that proposal.
- `function getProposal(uint256 _proposalId) public view returns (address ownerProposed_, uint256 approvalCount_, address[] memory guardiansApproved_)`: Returns stored information of a NewOwnerProposal for the specified proposal id.
  - Error `ACL:: invalid proposal id`: Has to be a valid proposal.
- `function guardianPropose(address _newOwner) external onlyGuardian`: Allows a guardian to propose adding a new `EtherspotWallet` owner. Only one proposal is allowed at any time and needs to either be actioned or discarded for another proposal to be submitted.
  - Error `ACL:: not enough guardians to propose new owner (minimum 3)`: Requires minimum amount of 3 guardians to add a new owner.
  - Emits `ProposalSubmitted(proposalId, _newOwner, msg.sender)`.
- `function guardianCosign() external onlyGuardian`: Allows other guardians than the one that proposed adding a new owner to cosign the proposal. If quorum (60% of total guardians) is not reached then `QuorumNotReached` event will be emitted. If quorum is reached, it will add a new owner. It will only allow for cosiging the current proposal as long as it is unresolved.
  - Error `ACL:: invalid proposal id`: Has to be a valid proposal.
  - Error `ACL:: guardian already signed proposal`: Guardian cannot sign proposal more than once.
  - Emits `QuorumNotReached(_proposalId, newOwner, proposals[_proposalId].approvalCount)`.
- `function discardCurrentProposal() external onlyOwnerOrGuardian`: Allows for a proposal to be discarded if it is decided that it will not be required/actioned.
  - Error `ACL:: proposal already resolved`: Checks that a proposal is not resolved. Cannot discard a resolved proposal.
  - Error `ACL:: guardian cannot discard proposal until timelock relased`: Checks that either the `INITIAL_PROPOSAL_TIMELOCK` + the time that the proposal was made is passed or, if the `proposalTimelock` variable has been set, whether that + the time that the proposal was made is passed. If false then it will revert if a guardian has called this function.
  - Emits `ProposalDiscarded(proposalId, msg.sender)`.

## Internal Functions

- `function _addOwner(address _newOwner) internal`: Adds a new owner.
  - Error `ACL:: zero address`: Cannot add zero address as owner.
  - Error `ACL:: already owner`: Address cannot already be an owner.
  - Error `ACL:: guardian cannot be owner`: Guardians cannot add themselves as an owner.
  - Emits `OwnerAdded(_newOwner)`.  
- `function _removeOwner(address _owner) internal`: Removes an existing owner.
  - Error `ACL:: removing self`: An owner cannot remove themselves.
  - Error `ACL:: non-existant owner`: Must be a valid owner to be removed.
  - Emits `OwnerRemoved(_owner)`.  
- `function _addGuardian(address _newGuardian) internal`: Adds a new guardian.
  - Error `ACL:: zero address`: Cannot add zero address as guardian.
  - Error `ACL:: already guardian`: Existing guardian cannot be re-added as a guardian.
  - Error `ACL:: guardian cannot be owner`: Guardians cannot be owners.
  - Emits `GuardianAdded(_newGuardian)`.  
- `function _removeGuardian(address _guardian) internal`: Removes an existing guardian.
  - Error `ACL:: non-existant guardian`: Must be a valid guardian to be removed.
  - Emits `GuardianRemoved(_guardian)`.  
- `function _checkIfSigned(uint256 _proposalId) internal view returns (bool)`: Checks if a guardian has cosigned a NewOwnerProposal.
- `function _checkQuorumReached(uint256 _proposalId) internal view returns (bool)`: Checks if a NewOwnerProposal has reached the required quorum to be processed or not.

## License

This contract is licensed under the MIT license.  
