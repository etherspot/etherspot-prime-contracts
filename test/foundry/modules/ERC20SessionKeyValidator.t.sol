// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../src/modular-etherspot-wallet/modules/validators/ERC20SessionKeyValidator.sol";
import "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import "../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import "../../../src/modular-etherspot-wallet/modules/executors/ERC20Actions.sol";
import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {VALIDATION_FAILED} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../TestAdvancedUtils.t.sol";
import "../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";

using ERC4337Utils for IEntryPoint;

contract ERC20SessionKeyValidatorTest is TestAdvancedUtils {
    using ECDSA for bytes32;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                  VARIABLES               */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    ModularEtherspotWallet mew;
    ERC20SessionKeyValidator validator;
    ERC20Actions erc20Action;
    TestERC20 erc20;

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    address alice;
    uint256 aliceKey;
    address bob;
    uint256 bobKey;
    address payable beneficiary;
    address sessionKeyAddr;
    uint256 sessionKeyPrivate;
    address sessionKey1Addr;
    uint256 sessionKey1Private;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*             HELPER FUNCTIONS              */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function _getPrevValidator(
        address _validator
    ) internal view returns (address) {
        // presuming that wallet wont have gt 20 different validators installed
        for (uint256 i = 1; i < 20; i++) {
            (address[] memory validators, ) = mew.getValidatorPaginated(
                address(0x1),
                i
            );
            if (validators[validators.length - 1] == _validator) {
                return validators[validators.length - 2];
            }
        }
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    SETUP                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function setUp() public override {
        super.setUp();
        validator = new ERC20SessionKeyValidator();
        erc20 = new TestERC20();
        erc20Action = new ERC20Actions();
        (sessionKeyAddr, sessionKeyPrivate) = makeAddrAndKey("session_key");
        (sessionKey1Addr, sessionKey1Private) = makeAddrAndKey("session_key_1");
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
        beneficiary = payable(address(makeAddr("beneficiary")));
        vm.deal(beneficiary, 1 ether);
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    TESTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function test_uninstallModule() public {
        mew = setupMEWWithSessionKeys();
        vm.startPrank(owner1);
        // install another validator module for total of 3
        Execution[] memory batchCall1 = new Execution[](1);
        batchCall1[0].target = address(mew);
        batchCall1[0].value = 0;
        batchCall1[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(defaultValidator),
            hex""
        );
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall1);
        // should be 3 validator modules installed
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(sessionKeyValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        // get previous validator to pass into uninstall
        // required for linked list
        address prevValidator = _getPrevValidator(address(sessionKeyValidator));
        // uninstall session key validator
        Execution[] memory batchCall2 = new Execution[](1);
        batchCall2[0].target = address(mew);
        batchCall2[0].value = 0;
        batchCall2[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.uninstallModule.selector,
            uint256(1),
            address(sessionKeyValidator),
            abi.encode(prevValidator, hex"")
        );
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall2);
        // check session key validator is uninstalled
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertFalse(mew.isModuleInstalled(1, address(sessionKeyValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        vm.stopPrank();
    }

    function test_pass_enableSessionKey() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transferFrom.selector,
            uint256(100),
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
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transferFrom.selector,
            uint256(100),
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
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        assertFalse(
            validator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
        // Rotate session key
        bytes memory newSessionData = abi.encodePacked(
            sessionKey1Addr,
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transferFrom.selector,
            uint256(2),
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
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
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
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        bytes memory sessionData2 = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transferFrom.selector,
            uint256(2),
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

        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transferFrom.selector,
            uint256(100),
            validAfter,
            validUntil
        );

        validator.enableSessionKey(sessionData);
        ERC20SessionKeyValidator.SessionData memory data = validator
            .getSessionKeyData(sessionKeyAddr);
        assertEq(data.token, address(erc20));
        assertEq(data.funcSelector, IERC20.transferFrom.selector);
        assertEq(data.validAfter, validAfter);
        assertEq(data.validUntil, validUntil);
    }

    function test_pass_validateUserOp() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));

        erc20.mint(address(mew), 10 ether);
        assertEq(erc20.balanceOf(address(mew)), 10 ether);
        erc20.approve(address(erc20Action), 5 ether);

        address[] memory allowedCallers = new address[](1);
        allowedCallers[0] = address(entrypoint);

        mew.installModule(
            MODULE_TYPE_FALLBACK,
            address(erc20Action),
            abi.encode(
                ERC20Actions.transferERC20Action.selector,
                CALLTYPE_SINGLE,
                allowedCallers,
                ""
            )
        );

        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            type(IERC20).interfaceId,
            ERC20Actions.transferERC20Action.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            ERC20Actions.transferERC20Action.selector,
            address(erc20),
            address(bob),
            uint256(5 ether)
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            data
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        // EIP712
        {
            bytes32 nameHash = keccak256(bytes("ERC20SessionKeyValidator"));
            bytes32 versionHash = keccak256(bytes("1.0.0"));
            bytes32 domainSeparator = keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(sessionKeyValidator)
                )
            );
            bytes32 signedMessageHash = keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, hash)
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                sessionKeyPrivate,
                ECDSA.toEthSignedMessageHash(signedMessageHash)
            );
            bytes memory signature = abi.encodePacked(r, s, v);

            userOp.signature = signature;
        }
        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);
        assertEq(erc20.balanceOf(address(bob)), 5 ether);
    }

    function test_fail_validateUserOp_invalidSessionKey() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));

        erc20.mint(address(mew), 10 ether);
        assertEq(erc20.balanceOf(address(mew)), 10 ether);
        erc20.approve(address(erc20Action), 5 ether);

        address[] memory allowedCallers = new address[](2);
        allowedCallers[0] = address(entrypoint);
        allowedCallers[1] = address(mew);

        mew.installModule(
            MODULE_TYPE_FALLBACK,
            address(erc20Action),
            abi.encode(
                ERC20Actions.transferERC20Action.selector,
                CALLTYPE_SINGLE,
                allowedCallers,
                ""
            )
        );

        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transferFrom.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );

        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(erc20),
            address(mew),
            address(bob),
            uint256(5 ether)
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            data
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        // EIP712
        {
            bytes32 nameHash = keccak256(bytes("ERC20SessionKeyValidator"));
            bytes32 versionHash = keccak256(bytes("1.0.0"));
            bytes32 domainSeparator = keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(sessionKeyValidator)
                )
            );
            bytes32 signedMessageHash = keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, hash)
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                sessionKeyPrivate,
                ECDSA.toEthSignedMessageHash(signedMessageHash)
            );
            bytes memory signature = abi.encodePacked(r, s, v);

            userOp.signature = signature;
        }
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Validation should fail
        sessionKeyValidator.disableSessionKey(sessionKeyAddr);
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA23 reverted",
                abi.encodeWithSignature("ERC20SKV_InvalidSessionKey()")
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_fail_validateUserOp_invalidFunctionSelector() public {
        mew = setupMEWWithSessionKeys();
        vm.startPrank(address(mew));
        // Construct and enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transfer.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct invalid selector user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(erc20),
            address(bob),
            address(mew),
            uint256(5 ether)
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            data
        );
        address sessionKeyValidatorAddr = address(sessionKeyValidator);
        userOp.nonce = uint256(uint160(sessionKeyValidatorAddr)) << 96;
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        // EIP712
        {
            bytes32 nameHash = keccak256(bytes("ERC20SessionKeyValidator"));
            bytes32 versionHash = keccak256(bytes("1.0.0"));
            bytes32 domainSeparator = keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(sessionKeyValidator)
                )
            );
            bytes32 signedMessageHash = keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, hash)
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                sessionKeyPrivate,
                ECDSA.toEthSignedMessageHash(signedMessageHash)
            );
            bytes memory signature = abi.encodePacked(r, s, v);

            userOp.signature = signature;
        }
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA23 reverted",
                abi.encodeWithSelector(
                    ERC20SessionKeyValidator
                        .ERC20SKV_UnsupportedSelector
                        .selector,
                    IERC20.transferFrom.selector
                )
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_fail_validateUserOp_sessionKeySpentLimitExceeded() public {
        mew = setupMEWWithSessionKeys();
        vm.startPrank(address(mew));
        // Construct and enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            type(IERC20).interfaceId,
            IERC20.transferFrom.selector,
            uint256(1 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct invalid selector user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(erc20),
            address(bob),
            address(mew),
            uint256(2 ether)
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            data
        );
        address sessionKeyValidatorAddr = address(sessionKeyValidator);
        userOp.nonce = uint256(uint160(sessionKeyValidatorAddr)) << 96;
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        // EIP712
        {
            bytes32 nameHash = keccak256(bytes("ERC20SessionKeyValidator"));
            bytes32 versionHash = keccak256(bytes("1.0.0"));
            bytes32 domainSeparator = keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(sessionKeyValidator)
                )
            );
            bytes32 signedMessageHash = keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, hash)
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                sessionKeyPrivate,
                ECDSA.toEthSignedMessageHash(signedMessageHash)
            );
            bytes memory signature = abi.encodePacked(r, s, v);

            userOp.signature = signature;
        }
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA23 reverted",
                abi.encodeWithSignature(
                    "ERC20SKV_SessionKeySpendLimitExceeded()"
                )
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }
}
