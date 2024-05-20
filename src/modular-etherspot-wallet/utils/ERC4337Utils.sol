// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEntryPoint} from "../../../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "solady/src/utils/ECDSA.sol";
import {Vm} from "forge-std/Test.sol";

library ERC4337Utils {
    function fillUserOp(
        IEntryPoint _entryPoint,
        address _sender,
        bytes memory _data
    ) internal view returns (PackedUserOperation memory op) {
        op.sender = _sender;
        op.nonce = _entryPoint.getNonce(_sender, 0);
        op.callData = _data;
        op.accountGasLimits = bytes32(
            abi.encodePacked(uint128(2e6), uint128(2e6))
        );
        op.preVerificationGas = 50000;
        op.gasFees = bytes32(abi.encodePacked(uint128(1), uint128(1)));
    }

    function signUserOpHash(
        IEntryPoint _entryPoint,
        Vm _vm,
        uint256 _key,
        PackedUserOperation memory _op
    ) internal view returns (bytes memory signature) {
        bytes32 hash = _entryPoint.getUserOpHash(_op);
        (uint8 v, bytes32 r, bytes32 s) = _vm.sign(
            _key,
            ECDSA.toEthSignedMessageHash(hash)
        );
        signature = abi.encodePacked(r, s, v);
    }
}
