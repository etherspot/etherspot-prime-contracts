# Audit Review And Changes (by Taek Lee)

## Scope

* AccessController.sol
* UniversalSignatureValidator.sol
* EtherspotPaymaster.sol
* Whitelist.sol
* EtherspotWallet.sol
* EtherspotWalletFactory.sol
* Proxy.sol

# First Review & Changes

## Issues Raised

| Severity |                       Description                    |  Status  |  Addressed  |
|:--------:|------------------------------------------------------|:--------:|:-----------:|
| Critical | Proxy slot inconsistency                             | Found    | Done        |
| High     | Sponsor cannot withdraw funds                        | Found    | Done        |
| Medium   | _pack() function has vulnerable packing method       | Found    | Done        |
| Low      | should return address when trying to deploy already deployed wallet | Found |  Done  |
| Info     | No need to inherit UniversalSigValidator             | Found    | Done        |
| Info     | Guardian has same role as owner                      | Found    | Question    |
| Info     | No need for senderNonce                              | Found    | Done        |

## Fixes Applied

### Proxy slot inconsistency

* Added implementation slot variable to `Proxy.sol`: Syncs up the implementation slot of `Proxy.sol` with `UUPS`.

### Sponsor cannot withdraw funds

* Added `withdrawFunds(address payable _sponsor, uint256 _amount)`: This is to solve the issue raised that sponsors could deposit funds to the paymaster but could not withdraw them.
  * checks that **msg.sender == _sponsor**: Only a sponsor can withdraw their tokens.
  * checks that **deposited funds >= amount**: Can't withdraw more funds that deposited.
* Added tests in suite to check successful withdrawal of funds, error thrown on msg.sender != sponsor and deposited funds < amount to withdraw.
* Added test util to parse error messages properly when not using callstatic methods.
* Added ReenterancyGuard as reentrancy lock for `withdrawFunds` and `depositFunds` as extra precaution against reentrancy attacks (functions already follow check-effects-interactions pattern).
* Added new `BasePaymaster.sol` that mimics the Infintism implementation but without the `withdrawTo` method to remove access for paymaster contract owner to remove funds.
* Added `_creditSponsor(address _sponsor, uint256 _amount)`: Required to follow debit and credit pattern recommended.
* Added `COST_OF_POST` constant which should be the pre calculated gas cost of the `_postOp` function call.
* Added `_debitSponsor` call in `_validatePaymasterUserOp` which debits the `requiredPreFund` amount from the sponsor. This should cover any gas costs that are incurred for the transaction.
* Added `costOfPost` variable in `_validatePaymasterUserOp`: This calculates the cost of the `_postOp` function call using the `userOp.gasPrice()`.
* Passing through two new pieces of information in conext of `_validatePaymasterUserOp` return information (`requiredPreFund` and `costOfPost`). This makes them available to be used in `_postOp`.
* Added `_creditSponsor` call in `_postOp`: This is encased in logic depending on result of `PostOpMode`. If `PostOpMode` == `postOpReverted` then the sponsor is not charged any gas and the full `requiredPreFund` amount is added back to the sponsor's balance. If it is `opReverted` or `opSucceeded` then sponsor balance is credited with the `requiredPreFund` minus `actualGasCost` + `costOfPost`:

```solidity
if (mode == PostOpMode.postOpReverted) {
            _creditSponsor(paymaster, prefundedAmount);
        } else {
            uint256 totalGasConsumed = actualGasCost + costOfPost;
            _creditSponsor(paymaster, prefundedAmount - totalGasConsumed);
        }
```

* Added tests in suite to check that amount is credited back to sponsors balance in `_postOp`.
* NEEDS TESTING TO MAKE SURE IT WORKS OK. CANT TEST PROPERLY IN SUITE WOULD NEED TO BE TESTED ON CHAIN.
  
### _pack() function has vulnerable packing method

* Changed `_pack`: Now similar `pack` found in `UserOperation.sol` ([here](https://github.com/eth-infinitism/account-abstraction/blob/abff2aca61a8f0934e533d0d352978055fddbd96/contracts/interfaces/UserOperation.sol#L63)) except with hashPaymasterAndData removed as not required (done separately in paymaster) and return type changed to `bytes32`.

### EtherspotWalletFactory should return address when trying to deploy already deployed wallet

* Added code block to check if `account.code.length > 0` for address and if so returns address.

### No need to inherit UniversalSigValidator

* Removed inheritance for `UniversalSigValidator` from EtherspotWallet.
* Abstracted `IERC721Wallet` from `UniversalSigValidator` contract file.
* Importing `IERC721Wallet` in EtherspotWallet.
* Written deployment script for `UniversalSigValidator` contract (as singleton).

### No need for senderNonce

* Removed `senderNonces`: Including mapping, increment in `_validatePaymasterUserOp` and no longer packed into `getHash` (except for `userOp.nonce`).

______________________________


# Second Review & Changes

## Issues Raised

| Severity |                       Description                    |  Status  |  Addressed  |
|:--------:|------------------------------------------------------|:--------:|:-----------:|
| Low      | EtherspotPaymaster uses banned opcode                | Found    | Done        |
| Low      | Adding owner/guardian inconsistency                  | Found    | Done        |
| Low      | Incorrect address check for adding new guardian      | Found    | Done        |
| Info     | Guardian has same role as owner                      | Found    | Done        |

## Fixes Applied

### EtherspotPaymaster uses banned opcode

* Change from `userOp.gasPrice()` to `userOp.maxFeePerGas` to avoid banned opcode.

### Adding owner/guardian inconsistency & incorrect address check for adding new guardian

* added `isOwner` check on `_addGuardian` function to make sure that a guardian is not already an owner.
* Amended `if (isGuardian(msg.sender) && msg.sender == _newOwner) revert()` to `if (isGuardian(_newOwner)) revert()`.

### Guardian has same role as owner

To address this issue we have decided to go the route of needing a quorum to approve a new owner:

* The minimum amount of guardians that are required to be able to add a new owner is now 3.
* The minimum quorum threshold required to allow a new owner is 60% (i.e. 2/3, 3/4, 3/5).  
* Only one proposal can be active at one time.
  
Proposal flow:

* A guardian wants to add a new owner.
* If there are 3 or more guardians in the Wallet then allowed to propose a new owner using `guardianPropose`.
* Other guardians can then cosign the proposal by calling `guardianCosgin` as long as certain checks are passed:
  * The proposal id passed into the function is valid
  * The guardian trying to cosign the proposal has not signed the proposal already
* If, on cosigning the proposal, quorum is still not reached, an event will be emitted and opening a new proposal will still be locked.
* If, on cosigning the proposal, quorum has been reached, a new owner will be added to the Wallet and new proposals will be accepted again.
* If, the proposal is invalid or not required, `discardCurrentProposal` is called to discard it and allow for new proposals.
  
There are some functions that have been added that assist this functionality:

* `getProposal`: returns proposal information.
* `_checkIfSigned`: helper to check if guardian has already signed proposal.
* `_checkQuorumReached`: helper to check is quorum has been reached for proposal.
  
* I have added tests in the test suite for these changes.
* Added information detailing the new functionality to ACCESS_CONTROLLER.md.
