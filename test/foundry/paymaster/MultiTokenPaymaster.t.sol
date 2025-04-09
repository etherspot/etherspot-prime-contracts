// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../../src/etherspot-wallet-v1/paymaster/MultiTokenPaymaster.sol";
import {IEntryPoint} from "../../../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";

/// To run: `forge test --mc "MultiTokenPaymasterTest" --mt "testParsePaymasterAndData" -vvvv --via-ir --optimize`
contract MultiTokenPaymasterTest is Test {
    MultiTokenPaymaster public mtp;
    IEntryPoint entrypoint;

    // Test constants
    address constant OWNER = address(0x1);
    address constant VERIFYING_SIGNER = address(0xdeadbeef);

    // Test data
    bytes paymasterAndData =
        hex"9db15065a6a36919ce7c93cd4387e57185c8725d0000000000000000000000000000afc800000000000000000000000000009c40000000000000000000000000000000000000000000000000000000000067f4ccdf0000000000000000000000000000000000000000000000000000000067f4ca4b0000000000000000000000004de0bb9ba339b16bdc4ac845dedf65a00d63213a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000000000000118c300bd0711041e695385e7f98485b771cba827014141c1bbcdd0f1f2e9137d77c0e0d6f0c58572f76e8f4d5b6620a41b5dec9b812905046a6fdd0920a29402844821b";

    function setUp() public {
        entrypoint = etchEntrypoint();
        // Deploy the MultiTokenPaymaster contract
        mtp = new MultiTokenPaymaster(OWNER, entrypoint, VERIFYING_SIGNER);
        console2.log("Test paymasterAndData length:", paymasterAndData.length);
    }

    function testParsePaymasterAndData() public {
        (
            MultiTokenPaymaster.ExchangeRateSource priceSource,
            uint48 validUntil,
            uint48 validAfter,
            address feeToken,
            address oracleAggregator,
            uint256 exchangeRate,
            uint32 priceMarkup,
            bytes memory signature
        ) = mtp.parsePaymasterAndData(paymasterAndData);
        console2.log("priceSource:", uint8(uint256(priceSource)));
        console2.log("validUntil:", validUntil);
        console2.log("validAfter:", validAfter);
        console2.log("feeToken:", feeToken);
        console2.log("oracleAggregator:", oracleAggregator);
        console2.log("exchangeRate:", exchangeRate);
        console2.log("priceMarkup:", priceMarkup);
        console2.logBytes(signature);
    }
}
