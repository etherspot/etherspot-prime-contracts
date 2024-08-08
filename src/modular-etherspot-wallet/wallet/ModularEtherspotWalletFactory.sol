// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {LibClone} from "solady/src/utils/LibClone.sol";
import {IModularEtherspotWallet} from "../interfaces/IModularEtherspotWallet.sol";
import {FactoryStaker} from "./FactoryStaker.sol";
contract ModularEtherspotWalletFactory is FactoryStaker {
    address public immutable implementation;

    event ModularAccountDeployed(
        address indexed account,
        address indexed owner
    );

    constructor(address _implementation, address _owner) FactoryStaker(_owner) {
        implementation = _implementation;
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
            emit ModularAccountDeployed(account, msg.sender);
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
