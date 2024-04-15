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

    address tar;
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
        tar = makeAddr("tar");
        beneficiary = payable(address(makeAddr("beneficiary")));
        vm.deal(beneficiary, 1 ether);
    }

    function testEnableAndDisableSessionKey() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        // Session should be enabled
        assertTrue(validator.checkValidSessionKey(sessionKeyAddr));
        // Disable session
        validator.disableSessionKey(sessionKeyAddr);
        vm.expectRevert(abi.encodeWithSignature("SSKV_InvalidSessionKey()"));
        // Session should now be disabled
        validator.checkValidSessionKey(sessionKeyAddr);
    }

    function testRotateSessionKey() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        assertTrue(validator.checkValidSessionKey(sessionKeyAddr));
        // Rotate session key
        bytes memory newSessionData = abi.encodePacked(
            sessionKey1Addr,
            ERC721Actions.transferERC721Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        validator.rotateSessionKey(sessionKeyAddr, newSessionData);
        assertTrue(validator.checkValidSessionKey(sessionKey1Addr));
        vm.expectRevert(abi.encodeWithSignature("SSKV_InvalidSessionKey()"));
        validator.checkValidSessionKey(sessionKeyAddr);
    }

    function testSessionPause() public {
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

    function testGetAssociatedSessionKeys() public {
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

    function testGetSessionKeyData() public {
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

    function testValidateSignature() public {
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
        // Disable session
        validator.disableSessionKey(sessionKeyAddr);
        // Validation should now fail
        uint256 validSigFail = validator.validateSignature(hash, signature);
        assertEq(validSigFail, VALIDATION_FAILED);
        // Re-enable same session key
        validator.enableSessionKey(sessionData);
        // Construct hash
        hash = keccak256(abi.encodePacked(alice, bob, (uint256)(1 ether)));
        (v, r, s) = vm.sign(sessionKeyPrivate, hash);
        // Validate signature
        signature = abi.encodePacked(r, s, v);
        validationData = validator.validateSignature(hash, signature);
        assertTrue(validationData != VALIDATION_FAILED);
    }

    function testValidateUserOp() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));

        address[] memory allowedCallers = new address[](1);
        allowedCallers[0] = address(entrypoint);

        mew.installModule(
            MODULE_TYPE_FALLBACK,
            address(mockFallback),
            abi.encode(
                ERC721Actions.transferERC721Action.selector,
                CALLTYPE_DELEGATECALL,
                allowedCallers,
                ""
            )
        );

        console2.log("address(mew)", address(mew));
        console2.log("owner1", owner1);
        action = new ERC721Actions();
        erc721 = new TestERC721();
        erc721.mint(address(mew), 0);
        erc721.mint(address(mew), 1);
        console2.log("address(mew)", address(mew));
        console2.log("test erc721", address(erc721));

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

        // Validation should now fail
        sessionKeyValidator.disableSessionKey(sessionKeyAddr);
        vm.expectRevert(abi.encodeWithSignature("SSKV_InvalidSessionKey()"));
        sessionKeyValidator.validateUserOp(userOp, hash);
    }

    function test_fail_InvalidFunctionSelector() public {
        mew = setupMEWWithSessionKeys();
        vm.startPrank(address(mew));
        erc721 = new TestERC721();
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
