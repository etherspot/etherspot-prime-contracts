// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ModularEtherspotWallet} from "../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {ModularEtherspotWalletFactory} from "../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";
import {MultipleOwnerECDSAValidator} from "../src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator.sol";
import {ERC20SessionKeyValidator} from "../src/modular-etherspot-wallet/modules/validators/ERC20SessionKeyValidator.sol";
import {Bootstrap} from "../src/modular-etherspot-wallet/erc7579-ref-impl/utils/Bootstrap.sol";

/**
 * @author Etherspot.
 * @title  ModularEtherspotWalletScript.
 * @dev Deployment script for ModularEtherspotWallet. Deploys:
 * ModularEtherspotWallet implementation, ModularEtherspotWalletFactory, Bootstrap and MultipleOwnerECDSAValidator.
 */

contract ModularEtherspotWalletScript is Script {
    bytes32 immutable SALT =
        bytes32(abi.encodePacked("ModularEtherspotWallet:Create2:salt"));
    address constant DEPLOYER = 0x09FD4F6088f2025427AB1e89257A44747081Ed59;
    address constant EXPECTED_IMPLEMENTATION =
        0x202A5598bDba2cE62bFfA13EcccB04969719Fad9;
    address constant EXPECTED_FACTORY =
        0xf80D543Ca10B48AF07c65Ff508605c1737EFAF3F;
    address constant EXPECTED_BOOTSTRAP =
        0x1baCB2F1ef4fD02f02e32cCF70888D9Caeb5f066;
    address constant EXPECTED_MULTIPLE_OWNER_ECDSA_VALIDATOR =
        0x8c4496Ba340aFe5ac4148cfEA9ccbBCD54093143;

    function run() external {
        ModularEtherspotWallet implementation;
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        // Wallet Implementation
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

        // Wallet Factory
        console2.log("Deploying ModularEtherspotWalletFactory...");
        if (EXPECTED_FACTORY.code.length == 0) {
            ModularEtherspotWalletFactory factory = new ModularEtherspotWalletFactory{
                    salt: SALT
                }(EXPECTED_IMPLEMENTATION, DEPLOYER);
            if (address(factory) != EXPECTED_FACTORY) {
                revert("Unexpected wallet factory address!!!");
            } else {
                console2.log(
                    "Wallet factory deployed at address",
                    address(factory)
                );
                // bytes memory factCode = address(factory).code;
                // console2.logBytes(factCode);
            }
        } else {
            console2.log(
                "Wallet factory already deployed at address",
                EXPECTED_FACTORY
            );
        }

        // Deploy Bootstrap
        if (EXPECTED_BOOTSTRAP.code.length == 0) {
            Bootstrap bootstrap = new Bootstrap{salt: SALT}();
            if (address(bootstrap) != EXPECTED_BOOTSTRAP) {
                revert("Unexpected bootstrap address!!!");
            } else {
                console2.log(
                    "Bootstrap deployed at address",
                    address(bootstrap)
                );
                // bytes memory bootCode = address(bootstrap).code;
                // console2.logBytes(bootCode);
            }
        } else {
            console2.log(
                "Bootstrap already deployed at address",
                EXPECTED_BOOTSTRAP
            );
        }

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
                // bytes memory valCode = address(multipleOwnerECDSAValidator).code;
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
