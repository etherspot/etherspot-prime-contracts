// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {CredibleAccountValidator} from "../src/modular-etherspot-wallet/modules/validators/CredibleAccountValidator.sol";

/**
 * @author Etherspot.
 * @title  CredibleAccountValidatorScript.
 * @dev Deployment script for CredibleAccountValidator.
 */

contract CredibleAccountValidatorScript is Script {
    bytes32 immutable SALT =
        bytes32(
            abi.encodePacked(
                "ModularEtherspotWallet:CredibleAccountValidator:Create2:salt"
            )
        );
    // address constant EXPECTED_CREDIBLE_ACCOUNT_VALIDATOR = ;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        // CreibleAccountValidator
        console2.log("Deploying CredibleAccountValidator...");
        // if (EXPECTED_CREDIBLE_ACCOUNT_VALIDATOR.code.length == 0) {
        CredibleAccountValidator credibleAccountValidator = new CredibleAccountValidator{
                salt: SALT
            }();
        // if (
        //     address(credibleAccountValidator) !=
        //     EXPECTED_CREDIBLE_ACCOUNT_VALIDATOR
        // ) {
        //     revert("Unexpected contract address!!!");
        // } else {
        console2.log(
            "CredibleAccountValidator deployed at address",
            address(credibleAccountValidator)
        );
        //     }
        // } else {
        //     console2.log(
        //         "Already deployed at address",
        //         EXPECTED_CREDIBLE_ACCOUNT_VALIDATOR
        //     );
        // }
        // bytes memory valCode = address(credibleAccountValidator).code;
        // console2.logBytes(valCode);

        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
