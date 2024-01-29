// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library ErrorsLib {
    /// AccessController
    error OnlyOwnerOrSelf();
    error OnlyGuardian();
    error OnlyOwnerOrGuardianOrSelf();

    error AddingInvalidOwner();
    error RemovingInvalidOwner();
    error AddingInvalidGuardian();
    error RemovingInvalidGuardian();

    error WalletNeedsOwner();
    error NotEnoughGuardians();

    error ProposalResolved();
    error ProposalUnresolved();
    error AlreadySignedProposal();

    error ProposalTimelocked();
    error InvalidProposal();

    // EtherspotWallet7579 Errors
}
