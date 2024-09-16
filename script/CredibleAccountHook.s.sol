// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {CredibleAccountHook} from "../src/modular-etherspot-wallet/modules/hooks/CredibleAccountHook.sol";

/**
 * @author Etherspot.
 * @title  CredibleAccountHookScript.
 * @dev Deployment script for CredibleAccountHook.
 */

contract CredibleAccountHookScript is Script {
    bytes32 immutable SALT =
        bytes32(
            abi.encodePacked(
                "ModularEtherspotWallet:CredibleAccountHook:Create2:salt"
            )
        );
    // address constant EXPECTED_CREDIBLE_ACCOUNT_HOOK = ;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        // CreibleAccountHook
        console2.log("Deploying CredibleAccountHook...");
        // if (EXPECTED_CREDIBLE_ACCOUNT_HOOK.code.length == 0) {
        CredibleAccountHook credibleAccountHook = new CredibleAccountHook{
            salt: SALT
        }();
        // if (
        //     address(credibleAccountHook) !=
        //     EXPECTED_CREDIBLE_ACCOUNT_HOOK
        // ) {
        //     revert("Unexpected contract address!!!");
        // } else {
        console2.log(
            "CredibleAccountHook deployed at address",
            address(credibleAccountHook)
        );
        //     }
        // } else {
        //     console2.log(
        //         "Already deployed at address",
        //         EXPECTED_CREDIBLE_ACCOUNT_HOOK
        //     );
        // }
        // bytes memory valCode = address(credibleAccountHook).code;
        // console2.logBytes(valCode);

        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
