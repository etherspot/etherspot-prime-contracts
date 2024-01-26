// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/ERC7579/wallet/EtherspotWallet7579.sol";
import "../src/ERC7579/wallet/EtherspotWallet7579Factory.sol";
import "../src/ERC7579/modules/MultipleOwnerECDSAValidator.sol";
import "@ERC7579/src/utils/Bootstrap.sol";

/**
 * @author Etherspot.
 * @title  EtherspotWallet7579Script.
 * @dev Deployment script for EtherspotWallet7579. Deploys:
 * EtherspotWallet7579 implementation, EtherspotWallet7579 factory and MultipleOwnerECDSAValidator.
 */

contract EtherspotWallet7579Script is Script {
    bytes32 immutable SALT =
        bytes32(abi.encodePacked("EtherspotWallet:Create2:salt"));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting deployment sequence...");

        // Wallet Implementation
        console2.log("Deploying EtherspotWallet7579 implementation...");
        EtherspotWallet7579 implementation = new EtherspotWallet7579{
            salt: SALT
        }();
        console2.log(
            "Wallet implementation deployed at address",
            address(implementation)
        );
        bytes memory implCode = address(implementation).code;
        console2.logBytes(implCode);

        // Wallet Factory
        console2.log("Deploying EtherspotWallet7579Factory...");
        EtherspotWallet7579Factory factory = new EtherspotWallet7579Factory{
            salt: SALT
        }(address(implementation));
        console2.log("Wallet factory deployed at address", address(factory));
        bytes memory factCode = address(factory).code;
        console2.logBytes(factCode);

        // Deploy Bootstrap
        Bootstrap bootstrap = new Bootstrap{salt: SALT}();
        console2.log("Bootstrap deployed at address", address(bootstrap));
        bytes memory bootCode = address(bootstrap).code;
        console2.logBytes(bootCode);

        // Multiple Owner ECDSA Validator
        console2.log("Deploying MultipleOwnerECDSAValidator...");
        MultipleOwnerECDSAValidator validator = new MultipleOwnerECDSAValidator{
            salt: SALT
        }();
        console2.log(
            "MultipleOwnerECDSAValidator deployed at address",
            address(validator)
        );
        bytes memory valCode = address(validator).code;
        console2.logBytes(valCode);

        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
