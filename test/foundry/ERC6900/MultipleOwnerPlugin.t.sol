// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

import {EntryPoint} from "@ERC4337/core/EntryPoint.sol";
import {UserOperation} from "@ERC4337/interfaces/UserOperation.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {MultipleOwnerPlugin} from "../../../src/ERC6900/plugins/MultipleOwnerPlugin.sol";

import {IMultipleOwnerPlugin} from "../../../src/ERC6900/interfaces/IMultipleOwnerPlugin.sol";
import {ErrorsLib} from "../../../src/ERC6900/libraries/ErrorsLib.sol";

import {ContractOwner} from "@ERC6900/test/mocks/ContractOwner.sol";

contract MultipleOwnerPluginTest is Test {
    using ECDSA for bytes32;

    MultipleOwnerPlugin public plugin;
    EntryPoint public entryPoint;

    bytes4 internal constant _1271_MAGIC_VALUE = 0x1626ba7e;
    address public a;
    address public b;

    address public owner1;
    address public owner2;
    address public owner3;
    ContractOwner public contractOwner;

    // Event declarations (needed for vm.expectEmit)
    event OwnershipTransferred(
        address indexed account,
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnerAdded(address account, address added);
    event OwnerRemoved(address account, address removed);

    // Error declarations (needed for vm.expectRevert)
    error AlreadyAnOwner();
    error NotAnOwner();
    error NotAuthorized();

    function setUp() public {
        plugin = new MultipleOwnerPlugin();
        entryPoint = new EntryPoint();

        a = makeAddr("a");
        b = makeAddr("b");
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
        owner3 = makeAddr("owner3");
        contractOwner = new ContractOwner();
    }

    // Tests:
    // - uninitialized owner is empty array (no address at [0])
    // - transferOwnership result is returned via owner afterwards
    // - transferOwnership emits OwnershipTransferred event
    // - owners() returns correct value after transferOwnership
    // - owners() does not return a different account's owner
    // - requireFromOwner succeeds when called by owner
    // - requireFromOwner reverts when called by non-owner

    function test_uninitializedOwner() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
    }

    function test_ownerInitialization() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner1);
        assertEq(1, plugin.owners().length);
        assertEq(owner1, plugin.owners()[0]);
        assertTrue(plugin.isOwner(owner1));
    }

    function test_ownersInitializationEvent() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(a, address(0), owner1);
        plugin.transferOwnership(owner1);
        assertEq(owner1, plugin.owners()[0]);
    }

    function test_ownerMigration() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner1);
        assertEq(1, plugin.owners().length);
        assertEq(owner1, plugin.owners()[0]);
        assertTrue(plugin.isOwner(owner1));
        plugin.transferOwnership(owner2);
        assertEq(1, plugin.owners().length);
        assertEq(owner2, plugin.owners()[0]);
        assertTrue(plugin.isOwner(owner2));
        assertFalse(plugin.isOwner(owner1));
    }

    function test_ownerMigrationEvents() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(a, address(0), owner1);
        plugin.transferOwnership(owner1);
        assertEq(owner1, plugin.owners()[0]);
        assertEq(1, plugin.owners().length);
        assertTrue(plugin.isOwner(owner1));
        assertFalse(plugin.isOwner(owner2));
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(a, owner1, owner2);
        plugin.transferOwnership(owner2);
        assertEq(owner2, plugin.owners()[0]);
        assertEq(1, plugin.owners().length);
        assertTrue(plugin.isOwner(owner2));
        assertFalse(plugin.isOwner(owner1));
    }

    function test_ownerForSender() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner1);
        assertEq(owner1, plugin.owners()[0]);
        vm.startPrank(b);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner2);
        assertEq(owner2, plugin.owners()[0]);
    }

    function test_requireOwner() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner1);
        assertEq(owner1, plugin.owners()[0]);
        plugin.runtimeValidationFunction(
            uint8(
                IMultipleOwnerPlugin.FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF
            ),
            owner1,
            0,
            ""
        );
        vm.startPrank(b);
        vm.expectRevert(ErrorsLib.NotAuthorized.selector);
        plugin.runtimeValidationFunction(
            uint8(
                IMultipleOwnerPlugin.FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF
            ),
            owner1,
            0,
            ""
        );
    }

    function testFuzz_validateUserOpSig(
        string memory salt,
        UserOperation memory userOp
    ) public {
        // range bound the possible set of priv keys
        (address signer, uint256 privateKey) = makeAddrAndKey(salt);
        vm.startPrank(a);
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            userOpHash.toEthSignedMessageHash()
        );
        // sig cannot cover the whole userop struct since userop struct has sig field
        userOp.signature = abi.encodePacked(r, s, v);
        // sig check should fail
        uint256 success = plugin.userOpValidationFunction(
            uint8(IMultipleOwnerPlugin.FunctionId.USER_OP_VALIDATION_OWNER),
            userOp,
            userOpHash
        );
        assertEq(success, 1);
        // transfer ownership to signer
        plugin.transferOwnership(signer);
        assertEq(signer, plugin.owners()[0]);
        // sig check should pass
        success = plugin.userOpValidationFunction(
            uint8(IMultipleOwnerPlugin.FunctionId.USER_OP_VALIDATION_OWNER),
            userOp,
            userOpHash
        );
        assertEq(success, 0);
    }

    function testFuzz_isValidSigForEOAOwner(
        string memory salt,
        bytes32 digest
    ) public {
        // range bound the possible set of priv keys
        (address signer, uint256 privateKey) = makeAddrAndKey(salt);
        vm.startPrank(a);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        // sig check should fail
        assertEq(
            plugin.isValidSig(signer, digest, abi.encodePacked(r, s, v)),
            bytes4(0xFFFFFFFF)
        );
        // transfer ownership to signer
        plugin.transferOwnership(signer);
        assertEq(signer, plugin.owners()[0]);
        // sig check should pass
        assertEq(
            plugin.isValidSig(signer, digest, abi.encodePacked(r, s, v)),
            _1271_MAGIC_VALUE
        );
    }

    function testFuzz_isValidSigForMultipleEOAOwner(
        string memory salt,
        bytes32 digest
    ) public {
        (address signer, uint256 privateKey) = makeAddrAndKey(salt);
        vm.startPrank(a);
        vm.assume(signer != address(0));
        // transfer ownership to signer
        plugin.transferOwnership(owner1);
        assertEq(owner1, plugin.owners()[0]);
        // sign digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        // add new owner
        plugin.addOwner(a, signer);
        assertEq(signer, plugin.owners()[1]);
        // sig check should pass using second owner
        assertEq(
            plugin.isValidSig(signer, digest, abi.encodePacked(r, s, v)),
            _1271_MAGIC_VALUE
        );
    }

    function testFuzz_isValidSigForContractOwner(bytes32 digest) public {
        vm.startPrank(a);
        plugin.transferOwnership(address(contractOwner));
        assertEq(address(contractOwner), plugin.owners()[0]);
        bytes memory signature = contractOwner.sign(digest);
        assertEq(
            plugin.isValidSig(address(contractOwner), digest, signature),
            _1271_MAGIC_VALUE
        );
    }

    function test_addOwner() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner1);
        assertEq(owner1, plugin.owners()[0]);
        plugin.addOwner(a, owner2);
        assertEq(owner2, plugin.owners()[1]);
        assertEq(2, plugin.owners().length);
        assertTrue(plugin.isOwner(owner2));
        assertTrue(plugin.isOwner(owner1));
    }

    function test_addOwnerEvents() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner1);
        assertEq(owner1, plugin.owners()[0]);
        assertEq(1, plugin.owners().length);
        assertTrue(plugin.isOwner(owner1));
        assertFalse(plugin.isOwner(owner2));
        vm.expectEmit(true, true, true, true);
        emit OwnerAdded(a, owner2);
        plugin.addOwner(a, owner2);
        assertEq(owner2, plugin.owners()[1]);
        assertEq(2, plugin.owners().length);
        assertTrue(plugin.isOwner(owner1));
        assertTrue(plugin.isOwner(owner2));
    }

    function test_requireAddOwnerAlreadyAnOwner() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner1);
        assertEq(owner1, plugin.owners()[0]);
        plugin.addOwner(a, owner2);
        vm.expectRevert(AlreadyAnOwner.selector);
        plugin.addOwner(a, owner2);
    }

    function test_removeOwner() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner1);
        assertEq(owner1, plugin.owners()[0]);
        plugin.addOwner(a, owner2);
        assertEq(owner1, plugin.owners()[0]);
        assertEq(owner2, plugin.owners()[1]);
        assertEq(2, plugin.owners().length);
        assertTrue(plugin.isOwner(owner2));
        assertTrue(plugin.isOwner(owner1));
        plugin.removeOwner(a, owner2);
        assertEq(owner1, plugin.owners()[0]);
        assertEq(1, plugin.owners().length);
        assertTrue(plugin.isOwner(owner1));
        assertFalse(plugin.isOwner(owner2));
    }

    function test_removeOwnerEvents() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner1);
        plugin.addOwner(a, owner2);
        assertEq(owner1, plugin.owners()[0]);
        assertEq(owner2, plugin.owners()[1]);
        assertEq(2, plugin.owners().length);
        assertTrue(plugin.isOwner(owner1));
        assertTrue(plugin.isOwner(owner2));
        vm.expectEmit(true, true, true, true);
        emit OwnerRemoved(a, owner2);
        plugin.removeOwner(a, owner2);
        assertEq(1, plugin.owners().length);
        assertTrue(plugin.isOwner(owner1));
        assertFalse(plugin.isOwner(owner2));
    }

    function test_requireRemoveOwnerNotAnOwner() public {
        vm.startPrank(a);
        assertEq(0, plugin.owners().length);
        plugin.transferOwnership(owner1);
        assertEq(owner1, plugin.owners()[0]);
        vm.expectRevert(NotAnOwner.selector);
        plugin.removeOwner(a, owner2);
    }

    function test_allAccountOwners() public {
        vm.startPrank(a);

        assertEq(0, plugin.ownersOf(a).length);
        plugin.transferOwnership(owner1);
        plugin.addOwner(a, owner2);
        plugin.addOwner(a, owner3);

        assertEq(3, plugin.ownersOf(a).length);
        bytes memory expected = abi.encodePacked([owner1, owner2, owner3]);
        assertEq(expected, abi.encodePacked(plugin.ownersOf(a)));
    }
}
