// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ProofVerifier} from "../../src/modular-etherspot-wallet/proof/ProofVerifier.sol";

/**
 * @author Etherspot
 * @title  ProofVerifier
 * @dev Deployment script for ProofVerifier used in CredibleAccountModule during verifyUserOp function to check if the proof of spending is valid
 */

// source .env & forge script script/resource-lock-contracts/ProofVerifier.s.sol:ProofVerifierScript1 --rpc-url "https://polygon-amoy-bor-rpc.publicnode.com" --broadcast -vvvv --ffi
contract ProofVeriferScript is Script {
    bytes32 immutable SALT =
        bytes32(
            abi.encodePacked(
                "ModularEtherspotWallet:ProofVerifier:Create2:salt"
            )
        );

    //address constant EXPECTED_IMPLEMENTATION = 0x58A7BcEe4E314e321029fCFa8155c6C1b9188c2F;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console2.log("Starting deployment sequence...");

        console2.log("Deploying ProofVerifier...");
        ProofVerifier proofVerifier = new ProofVerifier();
        console2.log(
            "ProofVerifier deployed at address",
            address(proofVerifier)
        );


        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
