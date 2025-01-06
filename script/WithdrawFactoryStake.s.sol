// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ModularEtherspotWalletFactory} from "../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";
import {IEntryPoint} from "../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {IStakeManager} from "../account-abstraction/contracts/interfaces/IStakeManager.sol";
/**
 * @author Etherspot.
 * @title  WithdrawFactoryStakeScript.
 * @dev Withdraws stake from EntryPoint for ModularEtherspotWalletFactory.
 */

contract WithdrawFactoryStakeScript is Script {
    address payable constant DEPLOYER =
        payable(0x09FD4F6088f2025427AB1e89257A44747081Ed59);
    address constant ENTRY_POINT_07 =
        0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    address payable constant FACTORY =
        payable(0x37f7ca7f9ffD04525a18B9B905088D96D625853a);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Withdrawing stake from old factory...");
        ModularEtherspotWalletFactory factory = ModularEtherspotWalletFactory(
            FACTORY
        );
        IEntryPoint entryPoint = IEntryPoint(ENTRY_POINT_07);

        IStakeManager.DepositInfo memory info = entryPoint.getDepositInfo(
            address(factory)
        );

        console2.log("Staked amount:", info.stake);
        console2.log("Unlocked:", info.withdrawTime < block.timestamp);

        if (info.withdrawTime < block.timestamp) {
            factory.withdrawStake(ENTRY_POINT_07, DEPLOYER);
            console2.log("Stake withdrawn!");
        } else {
            console2.log("Not yet time to withdraw after delay");
            console2.log("Can withdraw after:", info.withdrawTime);
        }

        vm.stopBroadcast();
    }
}
