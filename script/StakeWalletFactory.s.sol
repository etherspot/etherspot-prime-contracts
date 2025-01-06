// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ModularEtherspotWalletFactory} from "../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";
import {IEntryPoint} from "../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {IStakeManager} from "../account-abstraction/contracts/interfaces/IStakeManager.sol";

/**
 * @author Etherspot.
 * @title  StakeWalletFactoryScript.
 * @dev Deployment script for staking wallet factory with EntryPoint.
 */

contract StakeWalletFactoryScript is Script {
    address constant ENTRY_POINT_07 =
        0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    address payable constant EXPECTED_WALLET_FACTORY =
        payable(0x37f7ca7f9ffD04525a18B9B905088D96D625853a);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ModularEtherspotWalletFactory factory = ModularEtherspotWalletFactory(
            EXPECTED_WALLET_FACTORY
        );
        IEntryPoint entryPoint = IEntryPoint(ENTRY_POINT_07);

        console2.log("Starting deployment sequence...");

        console2.log("Staking factory contract with EntryPoint...");
        // stake wallet factory
        factory.addStake{value: 1e16}(address(entryPoint), 86400);

        IStakeManager.DepositInfo memory info = entryPoint.getDepositInfo(
            EXPECTED_WALLET_FACTORY
        );

        console2.log("Staked amount:", info.stake);

        console2.log("Factory staked!");

        vm.stopBroadcast();
    }
}
