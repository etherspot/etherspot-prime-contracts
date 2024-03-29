// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import "../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";
import "../src/modular-etherspot-wallet/modules/MultipleOwnerECDSAValidator.sol";
import "../src/modular-etherspot-wallet/erc7579-ref-impl/utils/Bootstrap.sol";

/**
 * @author Etherspot.
 * @title  ModularEtherspotWalletScript.
 * @dev Deployment script for ModularEtherspotWallet. Deploys:
 * ModularEtherspotWallet implementation, ModularEtherspotWallet factory and MultipleOwnerECDSAValidator.
 */

contract ModularEtherspotWalletScript is Script {
    bytes32 immutable SALT =
        bytes32(abi.encodePacked("ModularEtherspotWallet:Create2:salt"));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        // Wallet Implementation
        console2.log("Deploying ModularEtherspotWallet implementation...");
        ModularEtherspotWallet implementation = new ModularEtherspotWallet{
            salt: SALT
        }();
        console2.log(
            "Wallet implementation deployed at address",
            address(implementation)
        );
        // bytes memory implCode = address(implementation).code;
        // console2.logBytes(implCode);

        // Wallet Factory
        console2.log("Deploying ModularEtherspotWalletFactory...");
        ModularEtherspotWalletFactory factory = new ModularEtherspotWalletFactory{
                salt: SALT
            }(address(implementation));
        console2.log("Wallet factory deployed at address", address(factory));
        // bytes memory factCode = address(factory).code;
        // console2.logBytes(factCode);

        // Deploy Bootstrap
        Bootstrap bootstrap = new Bootstrap{salt: SALT}();
        console2.log("Bootstrap deployed at address", address(bootstrap));
        // bytes memory bootCode = address(bootstrap).code;
        // console2.logBytes(bootCode);

        // Multiple Owner ECDSA Validator
        console2.log("Deploying MultipleOwnerECDSAValidator...");
        MultipleOwnerECDSAValidator validator = new MultipleOwnerECDSAValidator{
            salt: SALT
        }();
        console2.log(
            "MultipleOwnerECDSAValidator deployed at address",
            address(validator)
        );
        // bytes memory valCode = address(validator).code;
        // console2.logBytes(valCode);

        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
