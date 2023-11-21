// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

library ErrorsLib {
    // EtherspotWalletV2 Errors
    error AlwaysDenyRule();
    error AuthorizeUpgradeReverted(bytes revertReason);
    error ExecFromPluginNotPermitted(address plugin, bytes4 selector);
    error ExecFromPluginExternalNotPermitted(
        address plugin,
        address target,
        uint256 value,
        bytes data
    );
    error InvalidConfiguration();
    error PostExecHookReverted(
        address plugin,
        uint8 functionId,
        bytes revertReason
    );
    error PreExecHookReverted(
        address plugin,
        uint8 functionId,
        bytes revertReason
    );
    error PreRuntimeValidationHookFailed(
        address plugin,
        uint8 functionId,
        bytes revertReason
    );
    error RuntimeValidationFunctionMissing(bytes4 selector);
    error RuntimeValidationFunctionReverted(
        address plugin,
        uint8 functionId,
        bytes revertReason
    );
    error UnexpectedAggregator(
        address plugin,
        uint8 functionId,
        address aggregator
    );
    error UnrecognizedFunction(bytes4 selector);
    error UserOpValidationFunctionMissing(bytes4 selector);
}
