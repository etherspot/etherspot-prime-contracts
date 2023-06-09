# Audit Changes

# Scope

* AccessController.sol
* UniversalSignatureValidator.sol
* EtherspotPaymaster.sol
* Whitelist.sol
* EtherspotWallet.sol
* EtherspotWalletFactory.sol
* Proxy.sol

# Issues Raised

| Severity |                       Description                    |  Status  |  Addressed  |
|:--------:|------------------------------------------------------|:--------:|:-----------:|
| Critical | Proxy slot inconsistency                             | Found    | Done        |
| High     | Sponsor cannot withdraw funds                        | Found    | Done        |
| Medium   | _pack() function has vulnerable packing method       | Found    | Done        |
| Low      | should return address when trying to deploy already deployed wallet | Found |  Done  |
| Info     | No need to inherit UniversalSigValidator             | Found    | Done        |
| Info     | Guardian has same role as owner                      | Found    | Question    |
| Info     | No need for senderNonce                              | Found    | Done        |

# Fixes Applied

## Proxy slot inconsistency

* Added implementation slot variable to `Proxy.sol`: Syncs up the implementation slot of `Proxy.sol` with `UUPS`.

## Sponsor cannot withdraw funds

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
  
## _pack() function has vulnerable packing method

* Changed `_pack`: Now similar `pack` found in `UserOperation.sol` ([here](https://github.com/eth-infinitism/account-abstraction/blob/abff2aca61a8f0934e533d0d352978055fddbd96/contracts/interfaces/UserOperation.sol#L63)) except with hashPaymasterAndData removed as not required (done separately in paymaster) and return type changed to `bytes32`.

## EtherspotWalletFactory should return address when trying to deploy already deployed wallet

* Added code block recommended in audit report. Checks if `account.code.length > 0` for address and if so returns address.

## No need to inherit UniversalSigValidator

* Removed inheritance for `UniversalSigValidator` from EtherspotWallet.
* Abstracted `IERC721Wallet` from `UniversalSigValidator` contract file.
* Importing `IERC721Wallet` in EtherspotWallet.
* Written deployment script for `UniversalSigValidator` contract (as singleton).

## Guardian has same role as owner

* Not sure I agree with this statement. Guardians cannot call `execute` or `executeBatch`. The only thing that Guardians should be able do is add/remove owners (for account recovery).

## No need for senderNonce

* Removed `senderNonces`: Including mapping, increment in `_validatePaymasterUserOp` and no longer packed into `getHash` (except for `userOp.nonce`).
