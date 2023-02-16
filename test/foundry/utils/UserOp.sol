// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {console} from "forge-std/console.sol";
import {UserOperation} from "../../../src/interfaces/UserOperation.sol";

contract UserOperationHelper {
    function helper_DefaultUserOpGen(address _sender)
        public
        pure
        returns (UserOperation memory)
    {
        UserOperation memory defaultUserOp;
        defaultUserOp.sender = _sender;
        defaultUserOp.nonce = 0;
        defaultUserOp.callData = "0x";
        defaultUserOp.callGasLimit = 0;
        defaultUserOp.verificationGasLimit = 100000;
        defaultUserOp.preVerificationGas = 21000;
        defaultUserOp.maxFeePerGas = 0;
        defaultUserOp.maxPriorityFeePerGas = 1e9;
        defaultUserOp.paymasterAndData;
        defaultUserOp.signature = "0x";
        return defaultUserOp;
    }
}
