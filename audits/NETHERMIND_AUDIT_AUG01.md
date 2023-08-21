# Nethermind Audit Report (Received: 01/08/2023)

## [Medium] Any guardian can remove owners from the Etherspot wallet

File(s): src/access/AccessController.sol

Description: The `removeOwner()` function from AccessController contract is used to remove an owner from the wallet. This function has the `ownlyOwnerOrGuardian` modifier, allowing an owner or guardian to call it. A malicious guardian can remove owners from the Etherspot wallet.

Recommendation(s): Consider restricting this action to only wallet owners.

Status: Fixed.

Fix: `removeOwner()` now uses `onlyOwner` modifier.

## [Medium] Dangerous use of _call forwarding all gas

File(s): src/wallet/EtherspotWallet.sol

Description: The `_call()` function executes a call to an external contract sending all available gas. By limiting the amount of gas, we reduce the surface attack by reducing the number of operations that an attacker can execute.

Recommendation(s): Discuss the possibility of limiting the amount of gas per transaction to limit the number of operations that an attacker can perform.

Status: Not fixed.

Comments: We are happy to proceed without changes. It would be difficult to estmate the gas for each execute call prior to making it and imposing limits might mean that we have to keep changing the implementation contract upon user's finding contracts that require a higher gas limit to call.

## [Medium] Improve the proposals’ voting design

File(s): src/access/AccessController.sol

Description: Below, we describe two issues with the voting system design.

Proposal design does not account for disagree votes: The current implementation of the proposal’s vote doesn’t work when the consensus discards a proposal. That is because the contract doesn’t keep track of the guardians who disagree, and there is no way to vote against a proposal.

As an example, if there are 3 guardians, one agrees to a proposal and the last two don’t; The guardian who agrees can call the function `guardianCosign()` function to make his vote, while the two other guardians who disagree don’t have a way to make their vote rather than just doing nothing. The owner (who can call the `discardCurrentProposal(...)` function) has no way to figure out if the majority of the guardians disagree.

In case there is not any available owner, the proposal could hang forever.

discardCurrentProposal can be abused: The `discardCurrentPropsal()` function has the modifier `onlyOwnerOrGuardian`. This modifier allows a malicious guardian to discard any proposal without waiting for its settlement.

Recommendation(s): The proposal design should a) account for disagreeing votes or b) implement expiration of the proposal after a specific duration. Additionally, Consider restricting the access to `discardCurrentProposal(...)` function to owners of the wallet.

Status: Partially fixed.

Fix: Added in a proposal timelock mechanism. This is set to 24 hours as a default but can be changed by the wallet owner. This will allow guardians to call `discardCurrentProposal()` and as long as the current timestamp is greater than the time at which the proposal was created (stored in the `NewOwnerProposal` struct) plus the proposal timelock period, it will allow guardians to remove proposals. If it does not comply with these parameters, then the call will revert.

Comments: I disagree with this example:

"As an example, if there are 3 guardians, one agrees to a proposal and the last two don’t; The guardian who agrees can call the function `guardianCosign()` function to make his vote, while the two other guardians who disagree don’t have a way to make their vote rather than just doing nothing. The owner (who can call the `discardCurrentProposal(...)` function) has no way to figure out if the majority of the guardians disagree."

If there are 3 guardians, then this would be the scenario:

1. guardian1 make the proposal.
2. guardian2 and guardian3 dont agree.
3. proposals require a 60% quorum to pass, therefore the proposal does not pass.

The way for the owner to see if the majority of guardians agree is that the proposal passes. If the proposal does not pass (or achieve quorum), then it is self-evident that the majority of guardians dont agree.

## [Low] In case a post user operation reverts, _postOp(...) function totally refunds the sponsor

File(s): src/paymaster/EtherspotPaymaster.sol

Description: In the contract EtherspotPaymaster, the `_postOp(...)` function is in charge of handling the user operation after it has been executed, reverted, or reverted during post-operation itself. This function contains accounting logic to refund the sponsor if the prefundedAmount is too high.

When the user operation succeeds but is reverted during `postOp()`, a second call to `postOp()` is done with `PostOpMode.postOpReverted` mode. The handling of this case totally refunds the sponsor, although the user operation has succeeded and consumed gas.

Recommendation(s): Consider removing the current handling of `PostOpMode.postOpReverted` mode and exclusively refund unsed gas to the sponsor (as currently done when the mode is different from `PostOpMode.postOpReverted`).

Status: Fixed.

Fix: Removed handling of `PostOpMode.postOpReverted` and now just refunds unused gas to the sponsor.

## [Low] _call function forwards all available gas to the external call

File(s): src/wallet/EtherspotWallet.sol

Description: The `_call()` function executes a call to an external contract sending all available gas. This function is used by executeBatch(...) that loops over an array of requests using only one userOperation. If all the gas is forwarded to each `_call()`, one external contract could act maliciously and consume all the gas. As a result, the following `_call()` would revert due to an out-of-gas error.

Recommendation(s): Consider adding an array of uint256 parameter (gasLimit) to the executeBatch() function. This parameter would specify the amount of gasLimit to forward to each call in the batch.

Status: Not fixed.

Comments: I believe that this is the same issue as [Medium] Dangerous use of _call forwarding all gas.

## [Low] proposalId 0 can be cosigned by guardians without being proposed

File(s): src/access/AccessController.sol

Description: The `proposalId` 0 can be cosigned by any guardian. This can block the creation of any proposal as in `guardianPropose(...)` it checks that the current amount of approving guardians in not 0:

Recommendation(s): Consider checking that the _proposalId is above 0:

Status: Fixed.

Fix: Added check `proposalId != 0`.

## [Info] Do not delete proposals from storage for traceability

File(s): src/access/AccessController.sol

Description: When a proposal is discarded or resolved, it is deleted from the storage of the smart contract. In case of an incident, it is easier to directly query the smart contract storage to go through all the pasts proposals. Moreover, the resolved does not denote if the proposal was discarded or passed through a quorum.

Recommendation(s): To have better traceability in case of an incident, consider not deleting the proposals. Moreover, consider adding a field that denotes the type of proposal settlement (discarded or passed).

Status: Fixed.

Fix: When discarding proposals, the data contained in the proposal is no longer deleted.

## [Info] Do not discard a proposal that is already resolved

File(s): src/access/AccessController.sol

Description: The `discardCurrentProposal()` function does not check that the current proposal is resolved before discarding it. Once a proposal is resolved, it should not be possible to discard it.

Recommendation(s): Before discarding a proposal, consider checking that the proposal still needs to be resolved.

Status: Fixed.

Fix: `discardCurrentProposal()` now checks to see if proposal has been resolved and function will revert if it has.

## [Info] Owners cannot remove themselves from the wallet

File(s): src/access/AccessController.sol

Description: The current implementation of `_removeOwner(...)` function disallows an owner from removing himself, even if other owners are in the wallet. The check of ownerCount is sufficient to ensure that the wallet is not ownerless.

Recommendation(s): Consider removing the check to allow an owner to remove himself from a wallet if he is not the only owner.

Status: Fixed.

Fix: Check for owner removing themselves has been removed.

## [Info] Removed guardian’s signature in the latest proposal remains valid

File(s): src/access/AccessController.sol

Description: If a guardian creates a new proposal or co-signs an existing one and he/she is removed afterward for his malicious behavior, his proposal/ signature will still be considered in the latest proposal.

function removeGuardian(address _guardian) external onlyOwner {
    _removeGuardian(_guardian);
}
Recommendation(s): Consider discarding the current proposal when one of the guardians is removed.

Status: Not fixed.

Comments: We are happy with this approach as it would still require a quorum of 60% of total guardians to pass, so even if there is one bad actor, it would require multiple votes to pass the proposal.

## [Info] Unnecessary inheritance

File(s): src/paymaster/Whitelist.sol

Description: The Whitelist contract is inheriting from Ownable library while it does not have any owner-specific operations. The code snippet is shown below.

Recommendation(s): Revisit the usage of Ownable library in the contract and consider removing the inheritance if it is not intended to be used.

Status: Fixed.

Fix: Removed Openzeppelin Ownable contract import.

## [Info] Unused variables in EtherspotWallet.sol

File(s): src/wallet/EtherspotWallet.sol

Description: Both `magicValue` and `validationData` variables are not respectively used in the functions `isValidSignature(...)` and `_validateSignature(...)`. The code snipet is reproduced below.

Recommendation(s): Remove unused variables from the returns signatures.

Status: Fixed.

Fix: Removed `magicValue` and `validationData` return variables.

## [Info] EntryPoint address should be immutable in EtherspotWallet contract

File(s): src/wallet/EtherspotWallet.sol

Description: According to the EIP-4337 standard, EntryPoint address contained in EtherspotWallet contract is expected to be hard-coded.

This component is a highly sensitive point of trust in the EIP-4337 architecture. There should be only one entry point deployed on a chain.

If a new entry point is deployed, users should update to a new version of the EtherspotWallet that would point to it. However, in the current implementation of the EtherspotWallet, the entry point address can be updated by the wallet owner.

Recommendation(s): Consider declaring `_entryPoint` variable as immutable and initialize its value within the constructor.

Status: Fixed.

Fix: Passing `_entryPoint` variable value in on implementation contract construction. Removed any ability to update this variable and the only way to do so is for a new implementation contract to be deployed and a user upgrade to that new implementation.

## [Info] EtherspotWallet can be initialized with the wrong EntryPoint contract address

File(s): src/wallet/EtherspotWallet.sol

Description: EtherspotWallet contract takes the EntryPoint contract address as a parameter during initialization. However, it does not perform a zero address check before assigning it.

Recommendation(s): Ensure that anEntryPoint is valid and not address(0).

Status: Fixed.

Fix: EntryPoint contract address is no longer passed in on initialization. Address checks provided for both EntryPoiny and WalletFactory (which is now passed in to provide callback to validate implementation).

## [Info] QuorumNotReached event has an incorrect parameter name

File(s): src/access/AccessController.sol

Description: The guardiansApproved field in the `NewOwnerProposal` structure is an array of addresses. However, the `guardiansApproved` parameter in the `QuorumNotReached` event is declared uint256 and represents the approval count. Using the same name within the structure and the event can be confusing. The code snippet is reproduced below.

Recommendation(s): Consider changing the parameter name.

Status: Fixed.

Fix: Renamed `guardiansApproved` in `QuorumNotReached` event to `approvalCount`.

## [Best Practice] onlyOwner modifier name represents incorrect logic

File(s): src/access/AccessController.sol

Description: There are three modifiers in the contract: `onlyOwnerOrEntryPoint`, `onlyOwnerOrGuardian`, and `onlyOwner`. The `onlyOwner` and `onlyOwnerOrGuardian` modifiers return true when the caller is address(this). However, `onlyOwnerOrEntryPoint` returns false in that case which can lead to some confusion.

Recommendation(s): Consider changing the modifier name to make it more explicit.

Status: Fixed

Fix: Added the same conditional for `address(this)` in `onlyOwnerOrEntryPoint`.

## [Best Practices] Apply Checks-Effects-Interactions pattern

File(s): src/paymaster/EtherspotPaymaster.sol

Description: The function depositFunds(...) violates the Checks Effects Interactions pattern as it makes an external call to entryPoint, followed by a state update of the sponsor funds (in _creditSponsor() function). The code is reproduced below.

Recommendation(s): Apply the Checks-Effects-Interactions pattern by placing the state update before the external call.

Status: Fixed.

Fix: Applied Checks-Effects-Interactions pattern.

## [Best Practices] Contract Whitelist does not use IWhitelist.sol

File(s): src/paymaster/Whitelist.sol

Description: The contract Whitelist.sol does not import the interface IWhitelist.sol, resulting in not using its functionalities. Additionally, some functions and events are declared in the interface but have yet to be used in the contract.

Recommendation(s): To avoid duplicated code, consider importing IWhitelist.sol interface in Whitelist.sol contract and remove unused events or functions from the interface declaration.

Status: Fixed.

Fix: Imported IWhitelist.sol interface in Whitelist.sol. Removed unused events.

## [Best Practices] Functions that can have external visibility

File(s): src/wallet/EtherspotWallet.sol,src/wallet/EtherspotWalletFactory.sol

Description: The following functions have public visibility instead of external. External functions and public functions are both used to allow external access to contract functions. However, there are some key differences between them. External functions are more gas-efficient compared to public functions. Moreover, external functions can only be called from outside the contract. This restriction can enhance security by preventing potential reentrancy attacks and unintended recursive calls that can be exploited to manipulate the contract state. Finally, using external functions improves the readability of the code. The functions that can be made external are listed below.

- `EtherspotWalletFactory.createAccount(...)`
- `EtherspotWallet.withdrawDepositTo(...)`

Recommendation(s): Set these functions’ visibility as `external`.

Status: Fixed.

Fix: set visibility of `EtherspotWalletFactory.createAccount(...)` and `EtherspotWallet.withdrawDepositTo(...)` to external.

## [Best Practices] Interface and implementation are not matching in EtherspotWallet.sol

File(s): src/wallet/EtherspotWallet.sol

Description: The contract EtherspotWallet.sol does not import the interface IEtherspotWallet.sol. The interface defines 5 events, while the contract only defines 3 events. The code snippets are shown below.

Recommendation(s): Remove contradictions between the interface and the contract.

Status: Fixed.

Fix: Removed unused/unnecessary events.

## [Best Practices] Remove unused UniversalSignatureValidator contract from the codebase

File(s): src/helpers/UniversalSignatureValidator.sol

Description: The UniversalSignatureValidator contract is not used anywhere in the code base of the Etherspot Wallet project. It seems to be a remainder from a previous version.

Recommendation(s): Remove unused contracts from the codebase.

Status: Fixed.

Fix: Removed.

## [Best Practices] Unclear function names in the Whitelist Contract

File(s): src/paymaster/Whitelist.sol

Description: The current function names in the Whitelist contract are unclear in conveying that they relate to whitelist functionalities. The functions `add(...)`, `addBatch(...)`, `remove(...)`, and `removeBatch(...)` perform operations on the whitelist, but their names do not explicitly indicate this. These functions’ names should be more specific as the Whitelist contract will be inherited and exposed by the EtherspotPaymaster contract.

Recommendation(s): To improve clarity, it is suggested to rename the functions to reflect better their purpose related to the whitelist, e.g., `addToWhitelist(...)`,`addBatchToWhitelist(...)`, `removeFromWhitelist(...)`, `removeBatchFromWhitelist(...)`.

Status: Fixed.

Fix: Amended function names to `addToWhitelist(...)`,`addBatchToWhitelist(...)`, `removeFromWhitelist(...)`, `removeBatchFromWhitelist(...)`.

## [Best Practices] Unnecessary usage of input parameter

File(s): src/paymaster/EtherspotPaymaster.sol

Description: The function `withdrawFunds(...)` takes `address payable _sponsor` as an input. However, it checks the funds and performs the withdrawal of `msg.sender` as he/she is the only one allowed to withdraw his/hers funds. The input is only checked to equal the `msg.sender` variable. The withdrawal can be exclusively based on the `msg.sender` variable instead of using the _sponsor parameter. The code snippet is shown below.

Recommendation(s): Consider removing the `_sponsor` parameter and use the `msg.sender` transaction variable.

Status: Fixed.

Fix: Removed `_sponsor` function parameter in favour of using `msg.sender`.

## [Best Practices] Unused WhitelistInitialized event in Whitelist.sol

File(s): src/paymaster/Whitelist.sol

Description: WhitelistInitialized event in Whitelist.sol is never emitted.

Recommendation(s): Check if you need the event. In case you don’t need it, remove any unused event declarations.

Status: Fixed.

Fix: Removed.

## [Best Practices] NewOwnerProposal struct is not reordered to consume less gas

File(s): src/access/AccessController.sol

Description: The struct `NewOwnerProposal` can be reordered to fit fewer slots. This reordering saves gas when storing new structure data in the smart contract storage.

Recommendation(s): Reorder struct properties like following.

Status: Fixed.

Fix: Rearranged variables in struction to `address newOwnerProposed; bool resolved; uint256 approvalCount; address[] guardiansApproved;`

## [Best Practices] accountImplementation cannot be updated

File(s): src/wallet/EtherspotWalletFactory.sol

Description: The accountImplementation variable stores the implementation address used to deploy new wallets. This variable is declared `immutable` in EtherspotWalletFactory.sol. It cannot be updated to set newer implementations.

Recommendation(s): Consider removing the `immutable` attribute to the `accountImplementation` variable and adding accessors functions to update it.

Status: Fixed.

Fix: Removed `immutable` keyword and added function for updating `accountImplementation`.

## [Best Practices] checkSponsorFunds name is confusing

File(s): src/paymaster/EtherspotPaymaster.sol

Description: The function `checkSponsorFunds(...)` within the EtherspotPaymaster.sol contract is a getter for the mapping `sponsorFunds` and does not check any specific condition. The current name can lead to misunderstandings.

Recommendation(s): Consider renaming the function to a more descriptive name that accurately reflects its role.

Status: Fixed.

Fix: Renamed mapping from `sponsorFunds` to `_sponsorBalances`. Renamed `checkSponsorFunds()` to `getSponsorBalance()`.
