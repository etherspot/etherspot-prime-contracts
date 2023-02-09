// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Utils} from "../foundry/utils/Utils.sol";
import {EntryPoint} from "../../src/core/EntryPoint.sol";
import {EtherspotAccount} from "../../src/EtherspotAccount.sol";
import {EtherspotPaymaster} from "../../src/TEST_EtherspotPaymaster.sol";
import {EtherspotAccountFactory} from "../../src/samples/EtherspotAccountFactory.sol";
import {UserOperation} from "../../src/interfaces/UserOperation.sol";

contract EtherspotPaymasterTest is Test {
    Utils internal utils;
    EntryPoint public entrypoint;
    EtherspotAccount public account;
    EtherspotPaymaster public etherspotpaymaster;
    EtherspotAccountFactory public accountfactory;

    address payable[] internal users;
    address internal alice;
    address internal bob;
    address internal charlie;

    event AddedToWhitelist(address paymaster, address account);
    event RemovedFromWhitelist(address paymaster, address account);

    function setUp() public {
        utils = new Utils();
        users = utils.createUsers(3);
        alice = vm.addr(1);
        bob = vm.addr(2);
        charlie = vm.addr(3);

        entrypoint = new EntryPoint();
        etherspotpaymaster = new EtherspotPaymaster(EntryPoint(entrypoint));
        accountfactory = new EtherspotAccountFactory(EntryPoint(entrypoint));
    }

    // #addToWhitelist
    function test_RevertWhen_AddToWhitelistZeroAddr() public {
        vm.expectRevert("EtherspotPaymaster:: Account cannot be address(0)");
        etherspotpaymaster.addToWhitelist(address(0));
    }

    function test_RevertWhen_AddToWhitelistAlreadyAdded() public {
        etherspotpaymaster.addToWhitelist(address(alice));
        vm.expectRevert("EtherspotPaymaster:: Account is already whitelisted");
        etherspotpaymaster.addToWhitelist(address(alice));
    }

    function test_AddToWhitelist() public {
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

    function test_Event_AddedToWhitelist() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit AddedToWhitelist(address(alice), address(bob));
        etherspotpaymaster.addToWhitelist(address(bob));
    }

    function testFuzz_AddToWhitelist(address x) public pure {
        vm.assume(x != address(0));
    }

    // #removeFromWhitelist
    function test_RevertWhen_RemoveFromWhitelistZeroAddr() public {
        vm.expectRevert("EtherspotPaymaster:: Account cannot be address(0)");
        etherspotpaymaster.removeFromWhitelist(address(0));
    }

    function test_RevertWhen_RemoveFromWhitelistNotAdded() public {
        vm.prank(address(alice));
        vm.expectRevert("EtherspotPaymaster:: Account is not whitelisted");
        etherspotpaymaster.removeFromWhitelist(address(bob));
    }

    function test_RemoveFromWhitelist() public {
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

    function test_Event_RemovedFromWhitelist() public {
        vm.prank(alice);
        etherspotpaymaster.addToWhitelist(address(bob));
        vm.expectEmit(true, true, false, false);
        emit RemovedFromWhitelist(address(alice), address(bob));
        vm.prank(alice);
        etherspotpaymaster.removeFromWhitelist(address(bob));
    }

    // helper
    function helper_DefaultUserOpGen(address _sender)
        internal
        pure
        returns (UserOperation memory)
    {
        UserOperation memory defaultUserOp;
        defaultUserOp.sender = _sender;
        defaultUserOp.nonce = 0;
        defaultUserOp.initCode = "0x";
        defaultUserOp.callData = "0x";
        defaultUserOp.callGasLimit = 0;
        defaultUserOp.verificationGasLimit = 100000;
        defaultUserOp.preVerificationGas = 21000;
        defaultUserOp.maxFeePerGas = 0;
        defaultUserOp.maxPriorityFeePerGas = 1e9;
        defaultUserOp.paymasterAndData = "0x";
        defaultUserOp.signature = "0x";
        return defaultUserOp;
    }

    // #validatePaymasterOp
    function test_RevertWhen_NoSignature() public {
        UserOperation memory userOp = helper_DefaultUserOpGen(alice);
        userOp.paymasterAndData = abi.encodePacked(
            address(etherspotpaymaster),
            "0x1234"
        );
        console.logBytes(userOp.paymasterAndData);
        vm.expectRevert("invalid signature length in paymasterAndData");
        entrypoint.simulateValidation(userOp);
    }

    // function test_RevertWhen_NoSignature() public {
    //     UserOperation memory userOp = helper_DefaultUserOpGen(alice);
    //     assertEq(userOp.sender, alice);
    //     console.log("alice: ", alice);
    //     bytes32 hash = etherspotpaymaster.getHash(userOp);
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
    //     address signer = ecrecover(hash, v, r, s);
    //     console.log("signer: ", signer);
    //     UserOperation memory userOp1 = helper_DefaultUserOpGen(alice);
    //     userOp1.paymasterAndData = abi.encodePacked(alice, signer);
    //     console.logBytes(userOp1.paymasterAndData);
    // }
}
