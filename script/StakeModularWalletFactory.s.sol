// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {IEntryPoint} from "../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {ModularEtherspotWalletFactory} from "../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";

/**
 * @author Etherspot.
 * @title  StakeModularWalletScript.
 * @dev Staking script for ModularEtherspotWalletFactory to EntryPoint contract.
 */

contract StakeModularWalletFactoryScript is Script {
    address constant ENTRY_POINT_07 =
        0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    address constant EXPECTED_FACTORY =
        0x8077765eA56BAc86D5936329131308B93871F695;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Staking wallet factory...");
        // stake wallet factory
        ModularEtherspotWalletFactory(EXPECTED_FACTORY).addStake{value: 1e16}(
            ENTRY_POINT_07,
            86400
        );
        console2.log("Factory staked!");

        vm.stopBroadcast();
    }
}
