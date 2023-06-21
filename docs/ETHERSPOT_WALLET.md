# EtherspotWallet.sol

## Overview

EtherspotWallet is a  EIP4337 compliant smart contract that acts as a multi-ownership wallet. It allows multiple owners to control a single account and execute transactions via an entry point contract. It also allows for guardian account recovery.

## Version

Solidity pragma version `^0.8.12`.  

## Imports

- `BaseAccount`: A contract that defines the interface for accounts and provides implementations for required methods for following the EIP4337 standards.  
- `UUPSUpgradeable`: A contract that enables the contract to be upgraded.  
- `Initializable`: A contract that provides support for initializer functions.  
- `TokenCallbackHandler`: A contract that defines the interface for token callbacks.  
- `IERC721Wallet`: A contract that provides support for ERC721 signature validation.  
- `AccessController`: A contract that provides support for owner and guardian management.  

## Variables

- `_entryPoint`: An IEntryPoint variable that holds the address of the entry point contract.  
- `_filler`: A bytes28 variable that serves as a filler.  
- `_nonce`: A uint96 variable that holds the current nonce.  

## Events

- `EtherspotWalletInitialized`: Emitted when the contract is initialized.  
- `EtherspotWalletReceived`: Emitted when the contract receives ether.  
- `EntryPointChanged`: Emitted when the entry point contract address is changed.  

## Modifiers

- `onlyOwner`: Allows only the owners of the contract to call the function.  
- `onlyOwnerOrGuardian`: Allows only the owners or guardians of the contract to call the function.  
- `onlyOwnerOrEntryPoint`: Allows only the owners or the entry point contract to call the function.  

## Public Functions

- `nonce() public view virtual override returns (uint256)`: Returns the current nonce.  
- `entryPoint() public view virtual override returns (IEntryPoint)`: Returns the entry point contract address.  
- `initialize(IEntryPoint anEntryPoint, address anOwner) public virtual initializer`: Initializes the contract. Calls `_initialize`.  
- `getDeposit() public view`: Returns the balance of the wallet deposited to the `EntryPoint` contract.  
- `addDeposit() public payable`: This function deposits tokens to the `EntryPoint` contract from wallet's address.  
- `withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyOwner`: Withdraws deposited tokens in the `EntryPoint` contract for the wallet to an external address. Only callable by wallet owner.  

## External Functions

- `receive() external payable`: A fallback function that is triggered when the contract receives ether.
  - Emits `EtherspotWalletReceived(address indexed from, uint256 indexed amount)`.  
- `execute(address dest, uint256 value, bytes calldata func) external onlyOwnerOrEntryPoint`: Executes a transaction. It can only be called by the owners or the entry point contract. It calls the _call() function.  
- `executeBatch(address[] calldata dest, bytes[] calldata func) external onlyOwnerOrEntryPoint`: Executes a sequence of transactions. It can only be called by the owners or the entry point contract. It calls the _call() function.  
- `updateEntryPoint(address _newEntryPoint) external`: Updates the `EntryPoint` contract stored in the wallet. Only callable by wallet owner.
  - Emits `EntryPointChanged(address(_entryPoint), _newEntryPoint)`.  
- `addOwner(address _newOwner) external onlyOwnerOrGuardian`: Adds a new owner to the `EtherspotWallet`. Interacts with the `Owned.sol`. Only callable by a wallet owner or an approved guardian. See OWNED.md for more information regarding this.  
- `removeOwner(address _owner) external onlyOwnerOrGuardian`: Removes an owner from the `EtherspotWallet`. Interacts with the `Owned.sol`. Only callable by a wallet owner or an approved guardian. See OWNED.md for more information regarding this.  
- `addGuardian(address _newGuardian) external onlyOwner`: Adds a new guardian to the `EtherspotWallet`. Interacts with the `Guarded.sol`. Only callable by a wallet owner. See GUARDED.md for more information regarding this.  
- `removeGuardian(address _guardian) external onlyOwner`: Removes a guardian from the `EtherspotWallet`. Interacts with the `Guarded.sol`. Only callable by a wallet owner. See GUARDED.md for more information regarding this.  

## Internal Functions

- `_initialize(IEntryPoint anEntryPoint, address anOwner) internal virtual`: Initializes the contract. It sets the entry point contract address and adds the initial owner.
  - Emits `event EtherspotWalletInitialized(IEntryPoint indexed entryPoint, address indexed owner)`.  
- `_validateAndUpdateNonce(UserOperation calldata userOp) internal override`: This function validates the user operation nonce and updates the wallet's nonce.  
- `_validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal virtual override`: This function validates the UserOperation signature.
- `_call(address target, uint256 value, bytes memory data) internal`: Makes a contract call to another smart contract.  
- `_authorizeUpgrade(address newImplementation) internal view override`: Upgrades `EtherspotWallet`. Only callable by wallet owner.

## License

This contract is licensed under the MIT license.  
