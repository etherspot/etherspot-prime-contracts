// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MultipleOwnerECDSAValidator} from "../src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator.sol";

/**
 * @author Etherspot.
 * @title  MultipleOwnerECDSAValidatorScript.
 * @dev Deployment script for MultipleOwnerECDSAValidator.
 */

contract MultipleOwnerECDSAValidatorScript is Script {
    bytes32 immutable SALT =
        bytes32(abi.encodePacked("ModularEtherspotWallet:Create2:salt"));
    address constant EXPECTED_MULTIPLE_OWNER_ECDSA_VALIDATOR =
        0xE6cEd8baB43E9386E0947b7b97A898e4620f3d15;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        // Multiple Owner ECDSA Validator
        console2.log("Deploying MultipleOwnerECDSAValidator...");
        if (EXPECTED_MULTIPLE_OWNER_ECDSA_VALIDATOR.code.length == 0) {
            MultipleOwnerECDSAValidator multipleOwnerECDSAValidator = new MultipleOwnerECDSAValidator{
                    salt: SALT
                }();
            if (
                address(multipleOwnerECDSAValidator) !=
                EXPECTED_MULTIPLE_OWNER_ECDSA_VALIDATOR
            ) {
                revert("Unexpected MultipleOwnerECDSAValidator address!!!");
            } else {
                console2.log(
                    "MultipleOwnerECDSAValidator deployed at address",
                    address(multipleOwnerECDSAValidator)
                );
                // bytes memory valCode = address(multipleOwnerECDSAValidator)
                //     .code;
                // console2.logBytes(valCode);
            }
        } else {
            console2.log(
                "MultipleOwnerECDSAValidator already deployed at address",
                EXPECTED_MULTIPLE_OWNER_ECDSA_VALIDATOR
            );
        }

        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
