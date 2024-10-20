// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ERC7484Registry} from "../../src/modular-etherspot-wallet/modules/registries/ERC7484Registry.sol";

/**
 * @author Etherspot.
 * @title  ERC7484Script
 * @dev Deployment script for ERC7484Script used in HookMultiplexer to check if the Hook being added to Multiplexer is a registered Hook
 */

// source .env & forge script script/resource-lock-contracts/ERC7484Registry.s.sol:ERC7484RegistryScript --rpc-url "https://polygon-amoy-bor-rpc.publicnode.com" --broadcast -vvvv --ffi
contract ERC7484RegistryScript is Script {
    bytes32 immutable SALT =
        bytes32(
            abi.encodePacked(
                "ModularEtherspotWallet:ERC7484Registry:Create2:salt"
            )
        );

    address constant EXPECTED_IMPLEMENTATION = 0x58A7BcEe4E314e321029fCFa8155c6C1b9188c2F;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console2.log("Starting deployment sequence...");

        // CreibleAccountModule
        console2.log("Deploying ERC7484Registry...");
        // if (EXPECTED_CREDIBLE_ACCOUNT_Module.code.length == 0) {
        ERC7484Registry erc7484Registry = new ERC7484Registry{
            salt: SALT
        }();
        // if (
        //     address(credibleAccountModule) !=
        //     EXPECTED_CREDIBLE_ACCOUNT_Module
        // ) {
        //     revert("Unexpected contract address!!!");
        // } else {
        console2.log(
            "ERC7484Registry deployed at address",
            address(erc7484Registry)
        );
        //     }
        // } else {
        //     console2.log(
        //         "Already deployed at address",
        //         EXPECTED_CREDIBLE_ACCOUNT_Module
        //     );
        // }
        // bytes memory valCode = address(credibleAccountModule).code;
        // console2.logBytes(valCode);

        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
