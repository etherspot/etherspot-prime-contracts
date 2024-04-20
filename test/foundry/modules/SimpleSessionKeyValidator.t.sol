// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../src/modular-etherspot-wallet/modules/validator/SimpleSessionKeyValidator.sol";
import "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import "../../../src/modular-etherspot-wallet/test/TestERC721.sol";
import "../../../src/modular-etherspot-wallet/test/ERC721Actions.sol";
import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {VALIDATION_FAILED} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../TestAdvancedUtils.t.sol";
import "../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";
import {MockFallback} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockFallbackHandler.sol";

using ERC4337Utils for IEntryPoint;

contract SimpleSessionKeyValidatorTest is TestAdvancedUtils {
    using ECDSA for bytes32;

    ModularEtherspotWallet mew;
    SimpleSessionKeyValidator validator;
    ERC721Actions action;
    TestERC721 erc721;
    MockFallback mockFallback;

    address alice;
    uint256 aliceKey;
    address bob;
    uint256 bobKey;
    address payable beneficiary;
    address sessionKeyAddr;
    uint256 sessionKeyPrivate;
    address sessionKey1Addr;
    uint256 sessionKey1Private;

    function setUp() public override {
        super.setUp();
        validator = new SimpleSessionKeyValidator();
        mockFallback = new MockFallback();
        (sessionKeyAddr, sessionKeyPrivate) = makeAddrAndKey("session_key");
        (sessionKey1Addr, sessionKey1Private) = makeAddrAndKey("session_key_1");
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
        beneficiary = payable(address(makeAddr("beneficiary")));
        vm.deal(beneficiary, 1 ether);
    }

    function test_pass_enableSessionKey() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        // Session should be enabled
        assertFalse(
            validator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
    }

    function test_pass_disableSessionKey() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        // Session should be enabled
        assertFalse(
            validator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
        // Disable session
        validator.disableSessionKey(sessionKeyAddr);
        // Session should now be disabled
        assertTrue(validator.getSessionKeyData(sessionKeyAddr).validUntil == 0);
    }

    function test_pass_rotateSessionKey() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        assertFalse(
            validator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
        // Rotate session key
        bytes memory newSessionData = abi.encodePacked(
            sessionKey1Addr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        validator.rotateSessionKey(sessionKeyAddr, newSessionData);
        assertFalse(
            validator.getSessionKeyData(sessionKey1Addr).validUntil == 0
        );
        assertTrue(validator.getSessionKeyData(sessionKeyAddr).validUntil == 0);
    }

    function test_pass_sessionPause() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        // Session should be enabled
        assertFalse(validator.checkSessionKeyPaused(sessionKeyAddr));
        // Disable session
        validator.toggleSessionKeyPause(sessionKeyAddr);
        // Session should now be disabled
        assertTrue(validator.checkSessionKeyPaused(sessionKeyAddr));
    }

    function test_pass_getAssociatedSessionKeys() public {
        bytes memory sessionData1 = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        bytes memory sessionData2 = abi.encodePacked(
            sessionKey1Addr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp + 2 days),
            uint48(block.timestamp + 3 days)
        );
        validator.enableSessionKey(sessionData1);
        validator.enableSessionKey(sessionData2);
        address[] memory sessionKeys = validator.getAssociatedSessionKeys();
        assertEq(sessionKeys.length, 2);
    }

    function test_pass_getSessionKeyData() public {
        uint48 validAfter = uint48(block.timestamp);
        uint48 validUntil = uint48(block.timestamp + 1 days);

        bytes memory sessionData1 = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            validAfter,
            validUntil
        );
        validator.enableSessionKey(sessionData1);
        SimpleSessionKeyValidator.SessionData memory data = validator
            .getSessionKeyData(sessionKeyAddr);
        assertEq(
            data.funcSelector,
            ERC721Actions.transferERC721Action.selector
        );
        assertEq(data.validAfter, validAfter);
        assertEq(data.validUntil, validUntil);
    }

    function test_pass_validateSignature() public {
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        // Construct hash
        bytes32 hash = keccak256(
            abi.encodePacked(alice, bob, (uint256)(1 ether))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        // Validate signature
        bytes memory signature = abi.encodePacked(r, s, v);
        uint256 validationData = validator.validateSignature(hash, signature);
        assertTrue(validationData != VALIDATION_FAILED);
    }

    function test_fail_validateSignature_invalidSessionKey() public {
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        // Construct hash
        bytes32 hash = keccak256(
            abi.encodePacked(alice, bob, (uint256)(1 ether))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        // Validate signature
        bytes memory signature = abi.encodePacked(r, s, v);
        // Disable session
        validator.disableSessionKey(sessionKeyAddr);
        // Validation should now fail
        uint256 validationData = validator.validateSignature(hash, signature);
        assertEq(validationData, VALIDATION_FAILED);
    }

    function test_pass_validateUserOp() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        action = new ERC721Actions();
        erc721 = new TestERC721();
        console.log("ERC721Action:", address(action));
        console2.log("TestERC721:", address(erc721));

        address[] memory allowedCallers = new address[](3);
        allowedCallers[0] = address(entrypoint);

        mew.installModule(
            MODULE_TYPE_FALLBACK,
            address(action),
            abi.encode(
                ERC721Actions.transferERC721Action.selector,
                CALLTYPE_SINGLE,
                allowedCallers,
                ""
            )
        );

        erc721.mint(address(mew), 0);
        erc721.approve(address(action), 0);
        assertEq(erc721.ownerOf(0), address(mew));

        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            ERC721Actions.transferERC721Action.selector,
            address(erc721),
            0,
            address(0xdead)
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            data
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        userOp.signature = abi.encodePacked(r, s, v);
        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);
        assertEq(erc721.ownerOf(0), address(0xdead));
    }

    function test_fail_validateUserOp_invalidSessionKey() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        action = new ERC721Actions();
        erc721 = new TestERC721();

        address[] memory allowedCallers = new address[](3);
        allowedCallers[0] = address(entrypoint);

        mew.installModule(
            MODULE_TYPE_FALLBACK,
            address(action),
            abi.encode(
                ERC721Actions.transferERC721Action.selector,
                CALLTYPE_SINGLE,
                allowedCallers,
                ""
            )
        );

        erc721.mint(address(mew), 0);
        erc721.approve(address(action), 0);
        assertEq(erc721.ownerOf(0), address(mew));

        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            ERC721Actions.transferERC721Action.selector,
            address(erc721),
            0,
            address(0xdead)
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            data
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        userOp.signature = abi.encodePacked(r, s, v);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Validation should fail
        sessionKeyValidator.disableSessionKey(sessionKeyAddr);
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA23 reverted",
                abi.encodeWithSignature("SSKV_InvalidSessionKey()")
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_fail_validateUserOp_invalidFunctionSelector() public {
        mew = setupMEWWithSessionKeys();
        vm.startPrank(address(mew));
        erc721 = new TestERC721();
        action = new ERC721Actions();
        // Construct and enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.invalidERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct invalid selector user op data
        bytes memory data = abi.encodeWithSelector(
            ERC721Actions.transferERC721Action.selector,
            address(mew),
            address(bob),
            (uint256)(1 ether)
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            data
        );
        address sessionKeyValidatorAddr = address(sessionKeyValidator);
        userOp.nonce = uint256(uint160(sessionKeyValidatorAddr)) << 96;
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        userOp.signature = abi.encodePacked(r, s, v);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA23 reverted",
                abi.encodeWithSignature("SSKV_UnsupportedSelector()")
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }
}
