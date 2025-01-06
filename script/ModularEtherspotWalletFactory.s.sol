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
    address public constant DEPLOYER =
        address(0x09FD4F6088f2025427AB1e89257A44747081Ed59);
    bytes32 public immutable SALT =
        bytes32(abi.encodePacked("ModularEtherspotWallet:Create2:salt"));
    address public constant EXPECTED_FACTORY =
        0x37f7ca7f9ffD04525a18B9B905088D96D625853a;
    address public constant EXPECTED_IMPLEMENTATION =
        0x6281a1A0DD1bA6415670F425bfBD78B322113CbB;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        /*//////////////////////////////////////////////////////////////
                      Deploy ModularEtherspotWalletFactory
        //////////////////////////////////////////////////////////////*/
        console2.log("Deploying ModularEtherspotWalletFactory...");
        if (EXPECTED_FACTORY.code.length == 0) {
            factory = new ModularEtherspotWalletFactory{salt: SALT}(
                EXPECTED_IMPLEMENTATION,
                DEPLOYER
            );
            if (address(factory) != EXPECTED_FACTORY) {
                revert("Unexpected wallet factory address!!!");
            } else {
                console2.log(
                    "Wallet factory deployed at address",
                    address(factory)
                );
                // bytes memory factCode = address(factory).code;
                // console2.logBytes(factCode);
            }
        } else {
            console2.log(
                "Wallet factory already deployed at address",
                EXPECTED_FACTORY
            );
        }

        console2.log("Finished deployment sequence!");
        vm.stopBroadcast();
    }
}
