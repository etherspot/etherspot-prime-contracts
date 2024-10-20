// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {ERC20SessionKeyValidator} from "../src/modular-etherspot-wallet/modules/validators/ERC20SessionKeyValidator.sol";

/**
 * @author Etherspot.
 * @title  ERC20SessionKeyValidatorScript.
 * @dev Deployment script for ERC20SessionKeyValidator.
 */
// source .env & forge script script/ERC20SessionKeyValidatorScript.s.sol:ERC20SessionKeyValidatorScript --rpc-url "https://polygon-amoy-bor-rpc.publicnode.com" --broadcast -vvvv --ffi
contract ERC20SessionKeyValidatorScript is Script {
    bytes32 immutable SALT =
        bytes32(abi.encodePacked("ModularEtherspotWallet:Create2:salt"));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // derive address from deployerPrivateKey
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployerAddress);
        

        console.log("Starting deployment sequence...");

        // ERC20 Session Key Validator
        console.log("Deploying ERC20SessionKeyValidator...");
        ERC20SessionKeyValidator erc20SessionKeyValidator = new ERC20SessionKeyValidator{
                salt: SALT
            }();
        console.log("Finished deployment of ERC20SessionKeyValidator!");

        vm.stopBroadcast();
    }
}
