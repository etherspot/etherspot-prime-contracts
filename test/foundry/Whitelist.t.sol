// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Utils} from "../foundry/utils/Utils.sol";
import {Whitelist} from "../../src/Whitelist.sol";

contract WhitelistTest is Test {
    Utils internal utils;

    Whitelist public wl;

    address payable[] internal users;
    address internal deployer;
    address internal alice;
    address internal bob;
    address internal charlie;
    address internal doris;
    address[] internal batch;

    event AddedToWhitelist(address indexed paymaster, address indexed account);
    event AddedBatchToWhitelist(
        address indexed paymaster,
        address[] indexed accounts
    );
    event RemovedFromWhitelist(
        address indexed paymaster,
        address indexed account
    );
    event RemovedBatchFromWhitelist(
        address indexed paymaster,
        address[] indexed accounts
    );

    function setUp() public {
        utils = new Utils();
        users = utils.createUsers(5);
        deployer = vm.addr(1);
        alice = vm.addr(2);
        bob = vm.addr(3);
        charlie = vm.addr(4);
        doris = vm.addr(5);
        batch = [address(bob), address(charlie), address(doris)];

        vm.prank(deployer);
        wl = new Whitelist();
    }

    // SUCCESS TESTING
    function testSuccess_WhitelistOwner() public {
        assertEq(deployer, wl.owner());
    }

    function testSuccess_WhitelistAdd() public {
        vm.startPrank(address(alice));
        wl.add(address(bob));
        assertTrue(wl.check(address(alice), address(bob)));
        vm.stopPrank();
    }

    function testSuccess_WhitelistAddBatch() public {
        vm.startPrank(address(alice));
        wl.addBatch(batch);
        assertTrue(wl.check(address(alice), address(bob)));
        assertTrue(wl.check(address(alice), address(charlie)));
        assertTrue(wl.check(address(alice), address(doris)));
        vm.stopPrank();
    }

    function testSuccess_WhitelistRemove() public {
        vm.startPrank(address(alice));
        wl.add(address(bob));
        assertTrue(wl.check(address(alice), address(bob)));
        wl.remove(address(bob));
        assertFalse(wl.check(address(alice), address(bob)));
        vm.stopPrank();
    }

    function testSuccess_WhitelistRemoveBatch() public {
        vm.startPrank(address(alice));
        wl.addBatch(batch);
        wl.removeBatch(batch);
        assertFalse(wl.check(address(alice), address(bob)));
        assertFalse(wl.check(address(alice), address(charlie)));
        assertFalse(wl.check(address(alice), address(doris)));
        vm.stopPrank();
    }

    // FAIL TESTING
    function testRevert_WhitelistAdd_ZeroAddr() public {
        vm.expectRevert("Whitelist:: Zero address");
        wl.add(address(0));
    }

    function testRevert_WhitelistAdd_AlreadyAdded() public {
        vm.startPrank(alice);
        wl.add(address(bob));
        vm.expectRevert("Whitelist:: Account is already whitelisted");
        wl.add(address(bob));
        vm.stopPrank();
    }

    function testRevert_WhitelistAddBatch_ZeroAddr() public {
        vm.startPrank(address(alice));
        batch.push(address(0));
        vm.expectRevert("Whitelist:: Zero address");
        wl.addBatch(batch);
        vm.stopPrank();
    }

    function testRevert_WhitelistAddBatch_AlreadyAdded() public {
        vm.startPrank(alice);
        wl.add(address(bob));
        vm.expectRevert("Whitelist:: Account is already whitelisted");
        wl.addBatch(batch);
        vm.stopPrank();
    }

    function testRevert_WhitelistRemove_ZeroAddr() public {
        vm.expectRevert("Whitelist:: Zero address");
        wl.remove(address(0));
    }

    function testRevert_WhitelistRemove_NotWhitelisted() public {
        vm.prank(address(alice));
        vm.expectRevert("Whitelist:: Account is not whitelisted");
        wl.remove(address(bob));
    }

    function testRevert_WhitelistRemoveBatch_ZeroAddr() public {
        vm.startPrank(address(alice));
        wl.addBatch(batch);
        batch.push(address(0));
        vm.expectRevert("Whitelist:: Zero address");
        wl.removeBatch(batch);
        vm.stopPrank();
    }

    function testRevert_WhitelistRemoveBatch_NotWhitelisted() public {
        vm.startPrank(alice);
        vm.expectRevert("Whitelist:: Account is not whitelisted");
        wl.removeBatch(batch);
        vm.stopPrank();
    }

    // EVENT TESTING
    function testEvent_WhitelistAdd_AddedToWhitelist() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit AddedToWhitelist(address(alice), address(bob));
        wl.add(address(bob));
    }

    function testEvent_WhitelistRemove_RemovedFromWhitelist() public {
        vm.startPrank(alice);
        wl.add(address(bob));
        vm.expectEmit(true, true, false, false);
        emit RemovedFromWhitelist(address(alice), address(bob));
        wl.remove(address(bob));
        vm.stopPrank();
    }

    function testEvent_WhitelistAddBatch_AddedBatchToWhitelist() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit AddedBatchToWhitelist(address(alice), batch);
        wl.addBatch(batch);
    }

    function testEvent_WhitelistRemoveBatch_RemovedBatchFromWhitelist() public {
        vm.startPrank(alice);
        wl.addBatch(batch);
        vm.expectEmit(true, true, false, false);
        emit RemovedBatchFromWhitelist(address(alice), batch);
        wl.removeBatch(batch);
        vm.stopPrank();
    }

    // GAS TESTING
    function testGas_WhitelistAdd() public {
        vm.prank(alice);
        uint256 initialGas = gasleft();
        wl.add(address(bob));
        uint256 remainingGas = gasleft();
        uint256 gasUsed = initialGas - remainingGas;
        assertLt(gasUsed, 0.001 ether);
        console.log("Whitelist: add(): gas cost:", gasUsed);
    }

    function testGas_WhitelistAddBatch_3() public {
        vm.prank(alice);
        uint256 initialGas = gasleft();
        wl.addBatch(batch);
        uint256 remainingGas = gasleft();
        uint256 gasUsed = initialGas - remainingGas;
        assertLt(gasUsed, 0.001 ether);
        console.log("Whitelist: addBatch(3): gas cost:", gasUsed);
    }

    function testGas_WhitelistRemove() public {
        vm.startPrank(alice);
        wl.add(address(bob));
        uint256 initialGas = gasleft();
        wl.remove(address(bob));
        uint256 remainingGas = gasleft();
        uint256 gasUsed = initialGas - remainingGas;
        assertLt(gasUsed, 0.001 ether);
        console.log("Whitelist: remove(): gas cost:", gasUsed);
        vm.stopPrank();
    }

    function testGas_WhitelistRemove_3() public {
        vm.startPrank(alice);
        wl.addBatch(batch);
        uint256 initialGas = gasleft();
        wl.removeBatch(batch);
        uint256 remainingGas = gasleft();
        uint256 gasUsed = initialGas - remainingGas;
        assertLt(gasUsed, 0.001 ether);
        console.log("Whitelist: removeBatch(3): gas cost:", gasUsed);
        vm.stopPrank();
    }

    function testGas_WhitelistCheck_True() public {
        vm.startPrank(alice);
        wl.add(address(bob));
        uint256 initialGas = gasleft();
        wl.check(address(alice), address(bob));
        uint256 remainingGas = gasleft();
        uint256 gasUsed = initialGas - remainingGas;
        assertLt(gasUsed, 0.001 ether);
        console.log("Whitelist: check() - true: gas cost:", gasUsed);
        vm.stopPrank();
    }

    function testGas_WhitelistCheck_False() public {
        vm.startPrank(alice);
        uint256 initialGas = gasleft();
        wl.check(address(alice), address(deployer));
        uint256 remainingGas = gasleft();
        uint256 gasUsed = initialGas - remainingGas;
        assertLt(gasUsed, 0.001 ether);
        console.log("Whitelist: check() - false: gas cost:", gasUsed);
        vm.stopPrank();
    }

    // FUZZ TESTING
    function testFuzz_WhitelistAdd(address x) public {
        vm.assume(x != address(0));
        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit AddedToWhitelist(address(alice), x);
        wl.add(x);
    }

    function testFuzz_WhitelistRemove(address x) public {
        vm.assume(x != address(bob) && x != address(0));
        vm.startPrank(alice);
        wl.add(address(bob));
        vm.expectRevert("Whitelist:: Account is not whitelisted");
        wl.remove(x);
        vm.stopPrank();
    }

    function testFuzz_WhitelistCheck(address x) public {
        vm.assume(x != address(bob));
        vm.startPrank(alice);
        wl.add(address(bob));
        assertFalse(wl.check(address(alice), x));
        vm.stopPrank();
    }
}
