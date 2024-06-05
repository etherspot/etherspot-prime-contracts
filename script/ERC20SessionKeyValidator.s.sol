// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ERC20SessionKeyValidator} from "../src/modular-etherspot-wallet/modules/validators/ERC20SessionKeyValidator.sol";

/**
 * @author Etherspot.
 * @title  ERC20SessionKeyValidatorScript.
 * @dev Deployment script for ERC20SessionKeyValidator.
 */

contract ERC20SessionKeyValidatorScript is Script {
    bytes32 immutable SALT =
        bytes32(abi.encodePacked("ModularEtherspotWallet:Create2:salt"));
    address constant EXPECTED_ERC20_SESSION_KEY_VALIDATOR =
        0xC1bb12d3a63b29C77963255827012706Fad0D3de;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        // ERC20 Session Key Validator
        console2.log("Deploying ERC20SessionKeyValidator...");
        if (EXPECTED_ERC20_SESSION_KEY_VALIDATOR.code.length == 0) {
            ERC20SessionKeyValidator erc20SessionKeyValidator = new ERC20SessionKeyValidator{
                    salt: SALT
                }();
            console2.log(
                "ERC20SessionKeyValidator deployed at address",
                address(erc20SessionKeyValidator)
            );
        } else {
            console2.log(
                "Already deployed at address",
                EXPECTED_ERC20_SESSION_KEY_VALIDATOR
            );
        }
        // bytes memory valCode = address(erc20SessionKeyValidator).code;
        // console2.logBytes(valCode);

        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
