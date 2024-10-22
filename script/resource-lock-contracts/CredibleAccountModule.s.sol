// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ProofVerifier} from "../../src/modular-etherspot-wallet/proof/ProofVerifier.sol";
import {CredibleAccountModule} from "../../src/modular-etherspot-wallet/modules/validators/CredibleAccountModule.sol";

/**
 * @author Etherspot.
 * @title  CredibleAccountModuleScript.
 * @dev Deployment script for ProofVerifier and CredibleAccountModule.
 */

// source .env & forge script script/resource-lock-contracts/CredibleAccountModule.s.sol:CredibleAccountModuleScript --rpc-url "https://polygon-amoy-bor-rpc.publicnode.com" --broadcast -vvvv --ffi
contract CredibleAccountModuleScript is Script {
    bytes32 immutable SALT =
        bytes32(
            abi.encodePacked(
                "ModularEtherspotWallet:CredibleAccountModule:Create2:salt"
            )
        );
    // replace placeholder with actual deployed address
    address constant HOOK_MULTIPLEXER = 0x370e65e9921f4F496e0Cb7c454B24DdC632eC862;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console2.log("Starting deployment sequence...");

        // ProofVerifier
        console2.log("Deploying ProofVerifier...");
        ProofVerifier proofVerifier = new ProofVerifier();
        console2.log(
            "ProofVerifier deployed at address",
            address(proofVerifier)
        );

        // CreibleAccountModule
        console2.log("Deploying CredibleAccountModule...");
        // if (EXPECTED_CREDIBLE_ACCOUNT_Module.code.length == 0) {
        CredibleAccountModule credibleAccountModule = new CredibleAccountModule(address(proofVerifier), HOOK_MULTIPLEXER);

        console2.log(
            "CredibleAccountModule deployed at address",
            address(credibleAccountModule)
        );
        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
