// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ProofVerifier} from "../src/modular-etherspot-wallet/proof/ProofVerifier.sol";
import {CredibleAccountModule} from "../src/modular-etherspot-wallet/modules/validators/CredibleAccountModule.sol";

/**
 * @author Etherspot.
 * @title  CredibleAccountModuleScript.
 * @dev Deployment script for ProofVerifier and CredibleAccountModule.
 */

contract CredibleAccountModuleScript is Script {
    bytes32 immutable SALT =
        bytes32(
            abi.encodePacked(
                "ModularEtherspotWallet:CredibleAccountModule:Create2:salt"
            )
        );
    // replace placeholder with actual deployed address
    address constant HOOK_MULTIPLEXER = address(0);
    // address constant EXPECTED_CREDIBLE_ACCOUNT_MODULE = ;

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
        CredibleAccountModule credibleAccountModule = new CredibleAccountModule{
            salt: SALT
        }(address(proofVerifier), HOOK_MULTIPLEXER);
        // if (
        //     address(credibleAccountModule) !=
        //     EXPECTED_CREDIBLE_ACCOUNT_Module
        // ) {
        //     revert("Unexpected contract address!!!");
        // } else {
        console2.log(
            "CredibleAccountModule deployed at address",
            address(credibleAccountModule)
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
