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
        MultipleOwnerECDSAValidator multipleOwnerECDSAValidator = new MultipleOwnerECDSAValidator{
                salt: SALT
            }();
        console2.log(
            "MultipleOwnerECDSAValidator deployed at address",
            address(multipleOwnerECDSAValidator)
        );
        // bytes memory valCode = address(multipleOwnerECDSAValidator).code;
        // console2.logBytes(valCode);

        // ERC20 Session Key Validator
        console2.log("Deploying ERC20SessionKeyValidator...");
        ERC20SessionKeyValidator erc20SessionKeyValidator = new ERC20SessionKeyValidator{
                salt: SALT
            }();
        console2.log(
            "ERC20SessionKeyValidator deployed at address",
            address(erc20SessionKeyValidator)
        );
        // bytes memory valCode = address(erc20SessionKeyValidator).code;
        // console2.logBytes(valCode);

        console2.log("Finished deployment sequence!");

        vm.stopBroadcast();
    }
}
