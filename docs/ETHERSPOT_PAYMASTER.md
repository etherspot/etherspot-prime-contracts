# EtherspotPaymaster.sol

## Overview
EtherspotPaymaster is a smart contract that allows an external signer to sign a UserOperation and pay for the gas costs of executing that UserOperation. The paymaster signs to agree to pay for gas, and the wallet signs to prove identity and account ownership.  

## Version
Solidity pragma version `^0.8.12`.  

## Global Variables
- `VALID_TIMESTAMP_OFFSET`: A constant of type uint256 that represents a 20 second time offset used to validate timestamps.  
- `SIGNATURE_OFFSET`: A constant of type uint256 that represents an 84-byte signature offset.  

## Imports
- `ECDSA`: A contract from the OpenZeppelin library used for signature verification.  
- `IERC20`: A contract from the OpenZeppelin library used for interacting with ERC20 tokens.  
- `SafeERC20`: A contract from the OpenZeppelin library used for safe ERC20 token transfers.  
- `Whitelist`: Whitelist.sol smart contract used for whitelisting addresses.  
  
## Mappings
- `sponsorFunds`: A mapping of type `mapping(address => uint256)` used to store the amount of sponsor funds transferred to the paymaster contract.  
- `senderNonce`: A mapping of type `mapping(address => uint256)` used to store the nonce of the sender.  

## Events
- `SponsorSuccessful`: An event emitted when a sponsor successfully sponsors a user operation.
- `SponsorUnsuccessful`: An event emitted when a sponsor is unsuccessful in sponsoring a user operation.  
  
## Constructor
- `constructor(IEntryPoint _entryPoint)`: A constructor that accepts an `IEntryPoint` parameter `_entryPoint`.  
  
## Public Functions
- `depositFunds() public payable `: A function used to deposit funds to the paymaster.
  - Error `EtherspotPaymaster:: Not enough balance`: Checks that the sponsor has enough funds to deposit into paymaster contract.  
- `checkSponsorFunds(address _sponsor) public view returns (uint256)`: A function used to check the amount of sponsor funds transferred to the paymaster contract for a given sponsor.  
- `function getHash(UserOperation calldata userOp, uint48 validUntil, uint48 validAfter) public view returns (bytes32)`: A function to return the hash to be sign off-chain (and validate on-chain) by a sponsor.  
- `function parsePaymasterAndData(bytes calldata paymasterAndData) public pure returns (uint48 validUntil, uint48 validAfter, bytes calldata signature)`: Extracts `validUntil`, `validAfter` and `signature` from `paymasterAndData` passed in as input.  

## Internal Functions
- `_debitSponsor(address _sponsor, uint256 _amount) internal`: A function used to debit a sponsors fund amount for gas costs once a transaction has been processed.  
- `_pack(UserOperation calldata userOp)`: A function used to pack the user operation.  
- `_validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 requiredPreFund)`: A function used to verify the external signer (sponsor) that signed the request.  
  - Error `EtherspotPaymaster:: invalid signature length in paymasterAndData`: Triggered on incorrect signature length.  
  - Error `EtherspotPaymaster:: Sponsor paymaster funds too low`: Checks sponsor has enough funds to pay the gas costs for a sponsored UserOperation.  
- `_postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override`: A function that overrides the `_postOp` function from `BasePaymaster.sol` that checks for a validated UserOperation and debits the sponsor's funds that signed that UserOperation.
  - Emits `SponsorSuccessful(paymaster, sender, userOpHash)` on successfully sponsored UserOperation.
  - Emits `SponsorUnsuccessful(paymaster, sender, userOpHash)` on unsuccessfully sponsored UserOperation.  

## License
This contract is licensed under the MIT license.  