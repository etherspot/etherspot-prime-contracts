# Whitelist.sol

## Overview
This smart contract is a simple whitelist implementation that allows an owner to add and remove addresses to/from a whitelist. The contract is designed in its current iteration to interact with `EtherspotPaymaster` contract to allow for a single Paymaster contract that can handle payments from sponsors to fund transaction gas for approved wallets.  

## Version
Solidity pragma version `^0.8.12`.  

### Mappings
`mapping(address => mapping(address => bool)) public whitelist`: A mapping of sponsor addresses to another mapping of account addresses to a boolean value that indicates whether the account address is whitelisted for the sponsor address.  

### Events
- `event WhitelistInitialized(address owner)`: Triggered when the contract is initialized.  
- `event AddedToWhitelist(address indexed paymaster, address indexed account)`: Triggered when an account is added to the whitelist for a specific paymaster.  
- `event AddedBatchToWhitelist(address indexed paymaster, address[] indexed accounts)`: Triggered when multiple accounts are added to the whitelist for a specific paymaster.  
- `event RemovedFromWhitelist(address indexed paymaster, address indexed account)`: Triggered when an account is removed from the whitelist for a specific paymaster.  
- `event RemovedBatchFromWhitelist(address indexed paymaster, address[] indexed accounts)`: Triggered when multiple accounts are removed from the whitelist for a specific paymaster.  

### External Functions
- `function check(address _sponsor, address _account) external view returns (bool)`: Checks if an account is whitelisted for a specific sponsor.  
- `function add(address _account) external`: Adds an account to the whitelist for the caller.
  - Emits `AddedToWhitelist(msg.sender, _account)`.  
- `function addBatch(address[] calldata _accounts) external`: Adds multiple accounts to the whitelist for the caller.
  - Emits`AddedBatchToWhitelist(msg.sender, _accounts)`.  
- `function remove(address _account) external`: Removes an account from the whitelist for the caller.
  - Emits `RemovedFromWhitelist(msg.sender, _account)`.  
- `function removeBatch(address[] calldata _accounts) external`: Removes multiple accounts from the whitelist for the caller.
  - Emits `RemovedBatchFromWhitelist(msg.sender, _accounts)`.  

### Internal Functions
- `function _check(address _sponsor, address _account) internal view returns (bool)`: Checks if an account is whitelisted for a specific sponsor.  
- `function _add(address _account) internal`: Adds an account to the whitelist for the caller.
  - Error `Whitelist:: Zero address`: Zero address cannot be added to whitelist.
  - Error `Whitelist:: Account is already whitelisted`: Existing whitelisted address cannot be re-added to the whitelist.  
- `function _addBatch(address[] calldata _accounts) internal`: Adds multiple accounts to the whitelist for the caller.  
- `function _remove(address _account) internal`: Removes an account from the whitelist for the caller.
  - Error `Whitelist:: Zero address`: Cannot try to remove zero address from whitelist.
  - Error `Whitelist:: Account is not whitelisted`: Must be a valid whitelisted account to be removed from whitelist.  
- `function _removeBatch(address[] calldata _accounts) internal`: Removes multiple accounts from the whitelist for the caller.  

### License
This contract is licensed under the MIT license.  