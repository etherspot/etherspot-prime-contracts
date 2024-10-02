// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {SessionKeyValidator} from "../src/modular-etherspot-wallet/modules/validators/SessionKeyValidator.sol";

contract SessionKeyValidatorScript is Script {
    bytes32 immutable SALT =
        bytes32(abi.encodePacked("SessionKeyValidator:Create2:salt"));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        // Deploy SessionKeyValidator
        console2.log("Deploying SessionKeyValidator...");
        SessionKeyValidator sessionKeyValidator = new SessionKeyValidator{
            salt: SALT
        }();
        console2.log(
            "SessionKeyValidator deployed at address",
            address(sessionKeyValidator)
        );

        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
