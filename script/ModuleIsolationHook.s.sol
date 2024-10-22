// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ModuleIsolationHook} from "../src/modular-etherspot-wallet/modules/hooks/ModuleIsolationHook.sol";

/**
 * @author Etherspot.
 * @title  ModuleIsolationHookScript
 */

// source .env & forge script script/ModuleIsolationHook.s.sol:ModuleIsolationHookScript --rpc-url "https://polygon-amoy-bor-rpc.publicnode.com" --broadcast -vvvv --ffi
contract ModuleIsolationHookScript is Script {
    bytes32 immutable SALT =
        bytes32(
            abi.encodePacked(
                "ModularEtherspotWallet:ModuleIsolationHook:Create2:salt"
            )
        );

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console2.log("Starting deployment sequence...");

        // CreibleAccountModule
        console2.log("Deploying ModuleIsolationHook...");
        // if (EXPECTED_CREDIBLE_ACCOUNT_Module.code.length == 0) {
        ModuleIsolationHook moduleIsolationHook = new ModuleIsolationHook{
            salt: SALT
        }();
        // if (
        //     address(credibleAccountModule) !=
        //     EXPECTED_CREDIBLE_ACCOUNT_Module
        // ) {
        //     revert("Unexpected contract address!!!");
        // } else {
        console2.log(
            "ModuleIsolationHook deployed at address",
            address(moduleIsolationHook)
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
