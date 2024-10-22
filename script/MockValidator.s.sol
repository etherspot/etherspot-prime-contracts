// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {MockValidator} from "../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockValidator.sol";

/**
 * @author Etherspot.
 * @title  ERC20SessionKeyValidatorScript.
 * @dev Deployment script for ERC20SessionKeyValidator.
 */
// source .env & forge script script/MockValidator.s.sol:MockValidatorScript --rpc-url "https://polygon-amoy-bor-rpc.publicnode.com" --broadcast -vvvv --ffi
contract MockValidatorScript is Script {
    // bytes32 immutable SALT =
    //     bytes32(abi.encodePacked("ModularEtherspotWallet:Create2:salt"));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // derive address from deployerPrivateKey
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployerAddress);
        

        console.log("Starting deployment sequence...");

        // ERC20 Session Key Validator
        console.log("Deploying mockValidator...");
        MockValidator mockValidator = new MockValidator();
        console.log("Finished deployment of mockValidator!");

        vm.stopBroadcast();
    }
}
