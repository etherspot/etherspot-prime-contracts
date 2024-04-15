// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../src/modular-etherspot-wallet/modules/validator/SimpleSessionKeyValidator.sol";
import "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import "../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import "../../../src/modular-etherspot-wallet/test/TestERC20Actions.sol";
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
    ERC20Actions action;
    TestERC20 erc20;
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
            TestERC20.testTransferFrom.selector,
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
            TestERC20.testTransferFrom.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        assertTrue(validator.checkValidSessionKey(sessionKeyAddr));
        // Rotate session key
        bytes memory newSessionData = abi.encodePacked(
            sessionKey1Addr,
            TestERC20.testTransferFrom.selector,
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
            TestERC20.testTransferFrom.selector,
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
            TestERC20.testTransferFrom.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        bytes memory sessionData2 = abi.encodePacked(
            sessionKey1Addr,
            TestERC20.testTransferFrom.selector,
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
            TestERC20.testTransferFrom.selector,
            validAfter,
            validUntil
        );
        validator.enableSessionKey(sessionData1);
        SimpleSessionKeyValidator.SessionData memory data = validator
            .getSessionKeyData(sessionKeyAddr);
        assertEq(data.funcSelector, TestERC20.testTransferFrom.selector);
        assertEq(data.validAfter, validAfter);
        assertEq(data.validUntil, validUntil);
    }

    function testValidateSignature() public {
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            TestERC20.testTransferFrom.selector,
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

        mew.installModule(
            MODULE_TYPE_FALLBACK,
            address(mockFallback),
            abi.encodePacked(
                MockFallback.staticCallTarget.selector,
                CALLTYPE_STATIC,
                ""
            )
        );

        console2.log("address(mew)", address(mew));
        console2.log("owner1", owner1);
        console2.log(
            "is fallback handler installed?",
            mockFallback.isInitialized(address(mew))
        );
        console2.log(
            "is multi ecdsa validator installed?",
            ecdsaValidator.isInitialized(address(mew))
        );
        action = new ERC20Actions();
        erc20 = new TestERC20(address(mew));
        console2.log("address(mew)", address(mew));
        console2.log("test erc20", address(erc20));

        uint256 preMEWBalance = erc20.balanceOf(address(mew));
        console2.log("pre MEW balance", preMEWBalance);
        uint256 preBobBalance = erc20.balanceOf(address(bob));
        console2.log("pre Bob balance", preBobBalance);

        erc20.approve(address(mew), 1 ether);

        // erc20.approve(address(action), 1 ether);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            ERC20Actions.transferERC20Action.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            ERC20Actions.transferERC20Action.selector,
            address(erc20),
            address(mew),
            address(bob),
            (uint256)(1 ether)
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            data
        );
        // userOp.nonce = uint256(uint160(sessionKeyValidatorAddr)) << 96;
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        userOp.signature = abi.encodePacked(r, s, v);
        // userOp.signature = bytes.concat(
        //     userOp.signature,
        //     entrypoint.signUserOpHash(vm, sessionKeyPrivate, userOp)
        // );
        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);

        uint256 postMEWBalance = erc20.balanceOf(address(mew));
        console2.log("post MEW balance", postMEWBalance);
        uint256 postBobBalance = erc20.balanceOf(address(bob));
        console2.log("post Bob balance", postBobBalance);
        // assertEq(erc20.balanceOf(address(mew)), (uint256)(0 ether));
        // assertEq(erc20.balanceOf(address(0xdead)), (uint256)(10 ether));
        // Disable session
        // sessionKeyValidator.disableSessionKey(sessionKeyAddr);
        // // Validation should now fail
        // vm.expectRevert(abi.encodeWithSignature("SSKV_InvalidSessionKey()"));
        // sessionKeyValidator.validateUserOp(userOp, userOpHash);
    }

    function test_fail_InvalidFunctionSelector() public {
        mew = setupMEWWithSessionKeys();
        vm.startPrank(address(mew));
        erc20 = new TestERC20(address(mew));
        erc20.approve(address(this), 1 ether);
        // Construct and enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            TestERC20.invalidFunc.selector,
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct invalid selector user op data
        bytes memory data = abi.encodeWithSelector(
            TestERC20.testTransferFrom.selector,
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

// computes the hash of a permit
function getStructHash(
    bytes4 sig,
    uint48 validUntil,
    uint48 validAfter,
    address validator,
    address executor,
    bytes memory enableData
) pure returns (bytes32) {
    return
        keccak256(
            abi.encode(
                keccak256(
                    "ValidatorApproved(bytes4 sig,uint256 validatorData,address executor,bytes enableData)"
                ),
                bytes4(sig),
                uint256(
                    uint256(uint160(validator)) |
                        (uint256(validAfter) << 160) |
                        (uint256(validUntil) << (48 + 160))
                ),
                executor,
                keccak256(enableData)
            )
        );
}

// computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
function getTypedDataHash(
    address sender,
    bytes4 sig,
    uint48 validUntil,
    uint48 validAfter,
    address validator,
    address executor,
    bytes memory enableData
) view returns (bytes32) {
    return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                _buildDomainSeparator(
                    "ModularEtherspotWallet",
                    "1.0.0",
                    sender
                ),
                getStructHash(
                    sig,
                    validUntil,
                    validAfter,
                    validator,
                    executor,
                    enableData
                )
            )
        );
}

function _buildDomainSeparator(
    string memory name,
    string memory version,
    address verifyingContract
) view returns (bytes32) {
    bytes32 hashedName = keccak256(bytes(name));
    bytes32 hashedVersion = keccak256(bytes(version));
    bytes32 typeHash = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    return
        keccak256(
            abi.encode(
                typeHash,
                hashedName,
                hashedVersion,
                block.chainid,
                address(verifyingContract)
            )
        );
}
