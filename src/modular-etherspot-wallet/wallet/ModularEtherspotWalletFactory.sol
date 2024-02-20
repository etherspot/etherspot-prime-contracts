// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {LibClone} from "@solady/utils/LibClone.sol";
import {IModularEtherspotWallet} from "../interfaces/IModularEtherspotWallet.sol";

contract ModularEtherspotWalletFactory {
    address public immutable implementation;

    constructor(address _ewImplementation) {
        implementation = _ewImplementation;
    }

    function createAccount(
        bytes32 salt,
        bytes calldata initCode
    ) public payable virtual returns (address) {
        bytes32 _salt = _getSalt(salt, initCode);
        (bool alreadyDeployed, address account) = LibClone
            .createDeterministicERC1967(msg.value, implementation, _salt);

        if (!alreadyDeployed) {
            IModularEtherspotWallet(account).initializeAccount(initCode);
        }
        return account;
    }

    function getAddress(
        bytes32 salt,
        bytes calldata initcode
    ) public view virtual returns (address) {
        bytes32 _salt = _getSalt(salt, initcode);
        return
            LibClone.predictDeterministicAddressERC1967(
                implementation,
                _salt,
                address(this)
            );
    }

    function _getSalt(
        bytes32 _salt,
        bytes calldata initCode
    ) public pure virtual returns (bytes32 salt) {
        salt = keccak256(abi.encodePacked(_salt, initCode));
    }
}
