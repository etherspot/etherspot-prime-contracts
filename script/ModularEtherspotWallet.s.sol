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
 * ModularEtherspotWallet implementation, ModularEtherspotWallet factory and MultipleOwnerECDSAValidator.
 */

contract ModularEtherspotWalletScript is Script {
    bytes32 immutable SALT =
        bytes32(abi.encodePacked("ModularEtherspotWallet:Create2:salt"));
    address constant EXPECTED_IMPLEMENTATION =
        0x202A5598bDba2cE62bFfA13EcccB04969719Fad9;
    address constant EXPECTED_FACTORY =
        0x059379cdb7Ee132De6a2281307bb4dC04a302064;
    address constant EXPECTED_BOOTSTRAP =
        0x1baCB2F1ef4fD02f02e32cCF70888D9Caeb5f066;
    address constant EXPECTED_MULTIPLE_OWNER_ECDSA_VALIDATOR =
        0x609d3ED5F7D1707806327D198Cb480B93dD6E6b9;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        // Wallet Implementation
        console2.log("Deploying ModularEtherspotWallet implementation...");
        ModularEtherspotWallet implementation = new ModularEtherspotWallet{
            salt: SALT
        }();
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

        // Wallet Factory
        console2.log("Deploying ModularEtherspotWalletFactory...");
        ModularEtherspotWalletFactory factory = new ModularEtherspotWalletFactory{
                salt: SALT
            }(address(implementation));
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

        // Deploy Bootstrap
        Bootstrap bootstrap = new Bootstrap{salt: SALT}();
        if (address(bootstrap) != EXPECTED_BOOTSTRAP) {
            revert("Unexpected bootstrap address!!!");
        } else {
            console2.log("Bootstrap deployed at address", address(bootstrap));
            // bytes memory bootCode = address(bootstrap).code;
            // console2.logBytes(bootCode);
        }

        // Multiple Owner ECDSA Validator
        console2.log("Deploying MultipleOwnerECDSAValidator...");
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
        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
