// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ModularEtherspotWalletFactory} from "../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";
import {IEntryPoint} from "../account-abstraction/contracts/interfaces/IEntryPoint.sol";
/**
 * @author Etherspot.
 * @title  ModularEtherspotWalletFactoryScript.
 * @dev Deployment script for ModularEtherspotWalletFactory.
 */

contract ModularEtherspotWalletFactoryScript is Script {
    address constant DEPLOYER =
        address(0x09FD4F6088f2025427AB1e89257A44747081Ed59);
    bytes32 immutable SALT =
        bytes32(abi.encodePacked("ModularEtherspotWallet:Create2:salt"));
    address implementation =
        address(0x202A5598bDba2cE62bFfA13EcccB04969719Fad9);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        // Wallet Factory
        console2.log("Deploying ModularEtherspotWalletFactory...");
        ModularEtherspotWalletFactory factory = new ModularEtherspotWalletFactory{
                salt: SALT
            }(implementation, DEPLOYER);
        console2.log("Wallet factory deployed at address", address(factory));
        // bytes memory factCode = address(factory).code;
        // console2.logBytes(factCode);

        console2.log("Finished deployment sequence!");
        vm.stopBroadcast();
    }
}
