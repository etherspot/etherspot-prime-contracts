// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ModularEtherspotWallet} from "../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";

/**
 * @author Etherspot.
 * @title  ModularEtherspotWalletScript.
 * @dev Deployment script for ModularEtherspotWallet. Deploys:
 * ModularEtherspotWallet.
 */

contract ModularEtherspotWalletScript is Script {
    bytes32 public immutable SALT =
        bytes32(abi.encodePacked("ModularEtherspotWallet:Create2:salt"));
    address public constant DEPLOYER =
        0x09FD4F6088f2025427AB1e89257A44747081Ed59;
    address public constant EXPECTED_IMPLEMENTATION =
        0x339eAB59e54fE25125AceC3225254a0cBD305A7b;

    function run() external {
        ModularEtherspotWallet implementation;
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        /*//////////////////////////////////////////////////////////////
                        Deploy ModularEtherspotWallet
        //////////////////////////////////////////////////////////////*/
        console2.log("Deploying ModularEtherspotWallet implementation...");
        if (EXPECTED_IMPLEMENTATION.code.length == 0) {
            implementation = new ModularEtherspotWallet{salt: SALT}();
            if (address(implementation) != EXPECTED_IMPLEMENTATION) {
                revert("Unexpected wallet implementation address!!!");
            } else {
                console2.log(
                    "Wallet implementation deployed at address",
                    address(implementation)
                );
                // bytes memory implCode = address(implementation).code;
                // console2.logBytes(implCode);
            }
        } else {
            console2.log(
                "Wallet implementation already deployed at address",
                EXPECTED_IMPLEMENTATION
            );
        }

        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
