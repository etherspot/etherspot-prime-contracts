// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {MSA as MSA_ValidatorInNonce} from "@ERC7579/src/accountExamples/MSA_ValidatorInNonce.sol";
import {AccessController} from "../access/AccessController.sol";
import {ArrayLib} from "../libraries/ArrayLib.sol";

contract EtherspotWallet7579 is AccessController, MSA_ValidatorInNonce {
    function execute(
        address target,
        uint256 value,
        bytes calldata callData
    ) external payable virtual override returns (bytes memory result) {
        // only allow ERC-4337 EntryPoint OR self OR owner (Ownable)
        // if (
        //     !(msg.sender == entryPoint() ||
        //         msg.sender == address(this) ||
        //         msg.sender == owner())
        // ) {
        //     revert AccountAccessUnauthorized();
        if (
            !(msg.sender == entryPoint() ||
                msg.sender == address(this) ||
                isOwner(msg.sender))
        ) {
            revert AccountAccessUnauthorized();
        }
        result = _execute(target, value, callData);
    }

    function initializeAccount(bytes calldata data) public virtual override {
        _addOwner(msg.sender);
        super.initializeAccount(data);
    }
}
