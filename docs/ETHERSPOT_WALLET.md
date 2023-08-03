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
- `_walletFactory`: An EtherspotWalletFactory variable that holds the address of the wallet factory.
- `ERC1271_SUCCESS`: An immutable return value for a successfull ERC1271 transaction.

## Events

- `EtherspotWalletInitialized`: Emitted when the contract is initialized.  
- `EtherspotWalletReceived`: Emitted when the contract receives ether.  
- `EntryPointChanged`: Emitted when the entry point contract address is changed.  

## Public Functions

- `nonce() public view virtual override returns (uint256)`: Returns the current nonce.  
- `entryPoint() public view virtual override returns (IEntryPoint)`: Returns the entry point contract address.  
- `initialize(IEntryPoint anEntryPoint, address anOwner) public virtual initializer`: Initializes the contract. Calls `_initialize`.  
- `getDeposit() public view`: Returns the balance of the wallet deposited to the `EntryPoint` contract.  

## External Functions

- `receive() external payable`: A fallback function that is triggered when the contract receives ether.
  - Emits `EtherspotWalletReceived(address indexed from, uint256 indexed amount)`.  
- `execute(address dest, uint256 value, bytes calldata func) external onlyOwnerOrEntryPoint`: Executes a transaction. It can only be called by the owners or the entry point contract. It calls the _call() function.  
- `executeBatch(address[] calldata dest, bytes[] calldata func) external onlyOwnerOrEntryPoint`: Executes a sequence of transactions. It can only be called by the owners or the entry point contract. It calls the _call() function.  
- `addDeposit() public payable`: This function deposits tokens to the `EntryPoint` contract from wallet's address.  
- `withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyOwner`: Withdraws deposited tokens in the `EntryPoint` contract for the wallet to an external address. Only callable by wallet owner.  

## Internal Functions

- `_initialize(IEntryPoint anEntryPoint, address anOwner) internal virtual`: Initializes the contract. It sets the entry point contract address and adds the initial owner.
  - Emits `event EtherspotWalletInitialized(IEntryPoint indexed entryPoint, address indexed owner)`.
- `_validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal virtual override`: This function validates the UserOperation signature.
- `_call(address target, uint256 value, bytes memory data) internal`: Makes a contract call to another smart contract.  
- `_authorizeUpgrade(address newImplementation) internal view override`: Upgrades `EtherspotWallet`. Only callable by wallet owner.
  - Error `EtherspotWallet:: upgrade implementation invalid`: Makes a callback to the EtherspotWalletFactory to check the new implementation address is correct.

## License

This contract is licensed under the MIT license.  
