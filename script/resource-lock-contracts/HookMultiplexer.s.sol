// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {HookMultiPlexer} from  "../../src/modular-etherspot-wallet/modules/hooks/multiplexer/HookMultiplexer.sol";
import {IERC7484} from "../../src/modular-etherspot-wallet/modules/registry/interfaces/IERC7484.sol";

/**
 * @author Etherspot.
 * @title  HookMultiplexerScript.
 * @dev Deployment script for HookMultiplexer
 */

// source .env & forge script script/resource-lock-contracts/HookMultiPlexer.s.sol:HookMultiPlexerScript \n --rpc-url "https://polygon-amoy-bor-rpc.publicnode.com" --broadcast -vvvv --ffi
// source .env & forge script script/resource-lock-contracts/HookMultiPlexer.s.sol:HookMultiPlexerScript \n --rpc-url "https://erpc.apothem.network" --broadcast -vvvv --ffi --legacy --gas-price 4000000

contract HookMultiPlexerScript is Script {
    bytes32 immutable SALT =
        bytes32(
            abi.encodePacked(
                "ModularEtherspotWallet:HookMultiplexer:Create2:salt"
            )
        );

    address constant ERC7484_REGISTRY = 0x8ae317E8E07A71C47a8073902Afc16fC97e3FF96;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console2.log("Starting deployment sequence...");

        console2.log("Deploying HookMultiplexer...");
        HookMultiPlexer hookMultiPlexer = new HookMultiPlexer(IERC7484(ERC7484_REGISTRY));
        console2.log(
            "ProofVerifier deployed at address",
            address(hookMultiPlexer)
        );
        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
