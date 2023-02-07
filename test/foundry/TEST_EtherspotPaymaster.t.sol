// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Utils} from "../foundry/utils/Utils.sol";
import {EntryPoint} from "../../src/core/EntryPoint.sol";
import {EtherspotAccount} from "../../src/EtherspotAccount.sol";
import {EtherspotPaymaster} from "../../src/TEST_EtherspotPaymaster.sol";

contract EtherspotPaymasterTest is Test {
    Utils internal utils;
    EntryPoint public entrypoint;
    EtherspotAccount public account;
    EtherspotPaymaster public etherspotpaymaster;

    address payable[] internal users;
    address internal alice;
    address internal bob;
    address internal charlie;

    struct UserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

    function setUp() public {
        utils = new Utils();
        users = utils.createUsers(3);
        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");
        charlie = users[2];
        vm.label(charlie, "Charlie");

        entrypoint = new EntryPoint();
        etherspotpaymaster = new EtherspotPaymaster(EntryPoint(entrypoint));
    }

    // #addToWhitelist
    function testFailAddToWhitelistZeroAddr() public {
        etherspotpaymaster.addToWhitelist(address(0));
    }

    function testFailAddToWhitelistAlreadyAdded() public {
        etherspotpaymaster.addToWhitelist(address(alice));
        etherspotpaymaster.addToWhitelist(address(alice));
    }

    function testAddToWhitelist() public {
        bool preAdd = etherspotpaymaster.whitelist(
            address(alice),
            address(bob)
        );
        assertFalse(preAdd);
        vm.prank(address(alice));
        etherspotpaymaster.addToWhitelist(address(bob));
        bool postAdd = etherspotpaymaster.whitelist(
            address(alice),
            address(bob)
        );
        assertTrue(postAdd);
    }

    // #removeFromWhitelist
    function testFailRemoveFromWhitelistZeroAddr() public {
        etherspotpaymaster.removeFromWhitelist(address(0));
    }

    function testFailRemoveFromWhitelistNotAdded() public {
        vm.prank(address(alice));
        etherspotpaymaster.removeFromWhitelist(address(bob));
    }

    function testRemoveFromWhitelist() public {
        bool preAdd = etherspotpaymaster.whitelist(
            address(alice),
            address(bob)
        );
        assertFalse(preAdd);
        vm.prank(address(alice));
        etherspotpaymaster.addToWhitelist(address(bob));
        bool postAdd = etherspotpaymaster.whitelist(
            address(alice),
            address(bob)
        );
        assertTrue(postAdd);
        vm.prank(address(alice));
        etherspotpaymaster.removeFromWhitelist(address(bob));
        bool postRemove = etherspotpaymaster.whitelist(
            address(alice),
            address(bob)
        );
        assertFalse(postRemove);
    }

    // #validatePaymasterOp
    function testFailRejectNoSig() public {
        UserOperation memory defaultUserOp;
        defaultUserOp.sender = address(alice);
        defaultUserOp.nonce = 0;
        defaultUserOp.initCode = "0x";
        defaultUserOp.callData = "0x";
        defaultUserOp.callGasLimit = 0;
        defaultUserOp.verificationGasLimit = 100000;
        defaultUserOp.preVerificationGas = 21000;
        defaultUserOp.maxFeePerGas = 0;
        defaultUserOp.maxPriorityFeePerGas = 1e9;
        defaultUserOp.paymasterAndData = "0x";
        vm.chainId(1);
        bytes32 hash = keccak256(
            defaultUserOp,
            address(entrypoint),
            block.chainid
        );
        defaultUserOp.signature = vm.sign(address(alice), hash);
    }

    // function testNumberIs42() public {
    //     assertEq(testNumber, 42);
    // }

    // function testFailSubtract43() public {
    //     testNumber -= 43;
    // }
}
