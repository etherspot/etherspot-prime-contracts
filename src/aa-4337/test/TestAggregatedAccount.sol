// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../../wallet/EtherspotWallet.sol";

/**
 * test aggregated-signature account.
 * works only with TestAggregatedSignature, which doesn't really check signature, but nonce sum
 * a true aggregated account should expose data (e.g. its public key) to the aggregator.
 */
contract TestAggregatedAccount is EtherspotWallet {
    address public immutable aggregator;

    // The constructor is used only for the "implementation" and only sets immutable values.
    // Mutable value slots for proxy accounts are set by the 'initialize' function.
    constructor(address anAggregator) EtherspotWallet() {
        aggregator = anAggregator;
    }

    /// @inheritdoc EtherspotWallet
    function initialize(
        IEntryPoint anEntryPoint,
        address
    ) public virtual override initializer {
        super._initialize(anEntryPoint, address(0));
    }

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view override returns (uint256 validationData) {
        (userOp, userOpHash);
        return _packValidationData(ValidationData(aggregator, 0, 0));
    }
}
