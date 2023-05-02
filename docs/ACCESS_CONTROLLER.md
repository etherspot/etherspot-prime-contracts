# AccessController.sol

## Overview
The `AccessController` abstract contract is a simple implementation that allows for wallet ownership/guardianship. It provides the functionality to check if an address is a owner or guardian, add a new owner an guardian, or remove an existing owner and guardian. It contains modifiers that check for ownership, guardianship and calls from `EntryPoint`. In it's current iteration it is designed to be used with `EtherspotWallet` to allow for wallets to have multiple owners and guardians.  

## Version
Solidity pragma version `^0.8.12`.  

## Modifiers
- `onlyOwner()`: check caller is an owner of the `EtherspotWallet` contract or `EtherspotWallet` contract itself.  
- `onlyOwnerOrGuardian()`: check caller is an owner of the `EtherspotWallet` contract, a guardian of the `EtherspotWallet` contract or `EtherspotWallet` contract itself.  
- - `onlyOwnerOrEntryPoint()`: check caller is an owner of the `EtherspotWallet` contract, the `EntryPoint` contract or `EtherspotWallet` contract itself.  

## Mappings
- `mapping(address => bool) private owners`: A mapping of addresses to boolean values that indicate whether the address is an owner or not.  
- `mapping(address => bool) private guardians`: A mapping of addresses to boolean values that indicate whether the address is a guardian or not.  

## Events
- `event OwnerAdded(address newOwner)`: Triggered when a new guardian is added.  
- `event OwnerRemoved(address removedOwner)`: Triggered when a guardian is removed.  
- `event GuardianAdded(address newGuardian)`: Triggered when a new guardian is added.  
- `event GuardianRemoved(address removedGuardian)`: Triggered when a guardian is removed.  

## Public Functions
- `function isOwner(address _address) public view returns (bool)`: Checks if an address is a owner or not.  
- `function isGuardian(address _address) public view returns (bool)`: Checks if an address is a guardian or not.  

## Internal Functions
- `function _addOwner(address _newOwner) internal`: Adds a new owner.
  - Error `Owned:: already an owner`: Address cannot already be an owner.
  - Emits `OwnerAdded(_newOwner)`.  
- `function _removeOwner(address _owner) internal`: Removes an existing owner.
  - Error `Owned:: cannot remove self`: An owner cannot remove themselves.
  - Error `Owned:: owner doesn't exist`: Must be a valid owner to be removed.
  - Emits `OwnerRemoved(_owner)`.  
- `function _addGuardian(address _newGuardian) internal`: Adds a new guardian.
  - Error `Guarded:: zero address can't be guardian`: Zero address cannot be guardian.
  - Error `Guarded:: already a guardian`: Existing guardian cannot be re-added as a guardian.
  - Emits `GuardianAdded(_newGuardian)`.  
- `function _removeGuardian(address _guardian) internal`: Removes an existing guardian.
  - Error `Guarded:: guardian doesn't exist`: Must be a valid guardian to be removed.
  - Emits `GuardianRemoved(_guardian)`.  

## License
This contract is licensed under the MIT license.  