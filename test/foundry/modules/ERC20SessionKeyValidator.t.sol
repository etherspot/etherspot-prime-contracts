// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../src/modular-etherspot-wallet/modules/validators/ERC20SessionKeyValidator.sol";
import "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import "../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import "../../../src/modular-etherspot-wallet/test/TestUSDC.sol";
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
    TestERC20 erc20;
    TestUSDC usdc;

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
    /*                   EVENTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    event ERC20SKV_ModuleInstalled(address wallet);
    event ERC20SKV_ModuleUninstalled(address wallet);
    event ERC20SKV_SessionKeyEnabled(address sessionKey, address wallet);
    event ERC20SKV_SessionKeyDisabled(address sessionKey, address wallet);
    event ERC20SKV_SessionKeyPaused(address sessionKey, address wallet);
    event ERC20SKV_SessionKeyUnpaused(address sessionKey, address wallet);

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*             HELPER FUNCTIONS              */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function _getPrevValidator(
        address _validator
    ) internal view returns (address) {
        // Presuming that wallet wont have gt 20 different validators installed
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
        usdc = new TestUSDC();
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

    function test_installModule() public {
        mew = setupMEW();
        vm.startPrank(owner1);
        // Install another validator module for total of 3
        Execution[] memory batchCall1 = new Execution[](1);
        batchCall1[0].target = address(mew);
        batchCall1[0].value = 0;
        batchCall1[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(sessionKeyValidator),
            hex""
        );
        // Check emitted event
        vm.expectEmit(false, false, false, true);
        emit ERC20SKV_ModuleInstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall1);
        // Should be 3 validator modules installed
        assertTrue(mew.isModuleInstalled(1, address(sessionKeyValidator), ""));
    }

    function test_uninstallModule() public {
        mew = setupMEWWithSessionKeys();
        vm.startPrank(address(mew));
        // Install another validator module for total of 3
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
        // Should be 3 validator modules installed
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(sessionKeyValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        // Check associated session keys == 1
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        assertEq(sessionKeyValidator.getAssociatedSessionKeys().length, 1);
        // Get previous validator to pass into uninstall (required for linked list)
        address prevValidator = _getPrevValidator(address(sessionKeyValidator));
        // Uninstall session key validator
        Execution[] memory batchCall2 = new Execution[](1);
        batchCall2[0].target = address(mew);
        batchCall2[0].value = 0;
        batchCall2[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.uninstallModule.selector,
            uint256(1),
            address(sessionKeyValidator),
            abi.encode(prevValidator, hex"")
        );
        // Check emitted event
        vm.expectEmit(false, false, false, true);
        emit ERC20SKV_ModuleUninstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall2);
        // Check session key validator is uninstalled
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertFalse(mew.isModuleInstalled(1, address(sessionKeyValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        assertFalse(sessionKeyValidator.isInitialized(address(mew)));
        assertEq(sessionKeyValidator.getAssociatedSessionKeys().length, 0);
        vm.stopPrank();
    }

    function test_pass_enableSessionKey() public {
        vm.startPrank(alice);
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        // Check emitted event
        vm.expectEmit(false, false, false, true);
        emit ERC20SKV_SessionKeyEnabled(sessionKeyAddr, address(alice));
        validator.enableSessionKey(sessionData);
        // Session should be enabled
        assertFalse(
            validator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
        vm.stopPrank();
    }

    function test_fail_enableSessionKey_invalidSessionKey_sessionKeyZeroAddress()
        public
    {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            address(0),
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20SessionKeyValidator.ERC20SKV_InvalidSessionKey.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_sessionKeyAlreadyExists() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20SessionKeyValidator
                    .ERC20SKV_SessionKeyAlreadyExists
                    .selector,
                sessionKeyAddr
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_invalidToken() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(0),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20SessionKeyValidator.ERC20SKV_InvalidToken.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_invalidFunctionSelector() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            bytes4(0),
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20SessionKeyValidator
                    .ERC20SKV_InvalidFunctionSelector
                    .selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_invalidSpendingLimit() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(0),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20SessionKeyValidator.ERC20SKV_InvalidSpendingLimit.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_invalidDuration() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp),
            uint48(block.timestamp)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20SessionKeyValidator.ERC20SKV_InvalidDuration.selector,
                block.timestamp,
                block.timestamp
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_pass_disableSessionKey() public {
        vm.startPrank(alice);
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        assertEq(validator.getAssociatedSessionKeys().length, 1);
        // Session should be enabled
        assertFalse(
            validator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
        // Check emitted event
        vm.expectEmit(false, false, false, true);
        emit ERC20SKV_SessionKeyDisabled(sessionKeyAddr, address(alice));
        // Disable session
        validator.disableSessionKey(sessionKeyAddr);
        // Session should now be disabled
        assertTrue(validator.getSessionKeyData(sessionKeyAddr).validUntil == 0);
        assertEq(validator.getAssociatedSessionKeys().length, 0);
        vm.stopPrank();
    }

    function test_pass_rotateSessionKey() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
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

    function test_fail_rotateSessionKey_invalidNewSessionData() public {
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        bytes memory invalidNewSessionData = abi.encodePacked(
            address(0),
            address(0),
            bytes4(0),
            uint256(0),
            uint48(0),
            uint48(0)
        );
        vm.expectRevert(
            ERC20SessionKeyValidator.ERC20SKV_InvalidSessionKey.selector
        );
        validator.rotateSessionKey(sessionKeyAddr, invalidNewSessionData);
    }

    function test_fail_rotateSessionKey_nonExistentKey() public {
        bytes memory newSessionData = abi.encodePacked(
            sessionKey1Addr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20SessionKeyValidator
                    .ERC20SKV_SessionKeyDoesNotExist
                    .selector,
                sessionKeyAddr
            )
        );
        validator.rotateSessionKey(sessionKeyAddr, newSessionData);
    }

    function test_pass_toggleSessionKeyPause() public {
        // Enable session
        vm.startPrank(alice);
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        // Session should be enabled
        assertFalse(validator.checkSessionKeyPaused(sessionKeyAddr));
        // Disable session
        vm.expectEmit(false, false, false, true);
        emit ERC20SKV_SessionKeyPaused(sessionKeyAddr, alice);
        validator.toggleSessionKeyPause(sessionKeyAddr);
        // Session should now be disabled
        assertTrue(validator.checkSessionKeyPaused(sessionKeyAddr));
        vm.expectEmit(false, false, false, true);
        emit ERC20SKV_SessionKeyUnpaused(sessionKeyAddr, alice);
        validator.toggleSessionKeyPause(sessionKeyAddr);
        vm.stopPrank();
    }

    function test_toggleSessionKeyPause_nonExistentKey() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20SessionKeyValidator
                    .ERC20SKV_SessionKeyDoesNotExist
                    .selector,
                sessionKeyAddr
            )
        );
        validator.toggleSessionKeyPause(sessionKeyAddr);
    }

    function test_pass_getAssociatedSessionKeys() public {
        bytes memory sessionData1 = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        bytes memory sessionData2 = abi.encodePacked(
            sessionKey1Addr,
            address(erc20),
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
        erc20.approve(address(mew), 5 ether);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(5 ether)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(erc20), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
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
        erc20.approve(address(mew), 5 ether);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(5 ether)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(erc20), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Validation should fail
        sessionKeyValidator.disableSessionKey(sessionKeyAddr);
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
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
            IERC20.transfer.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct invalid selector user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(5 ether)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(erc20), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        address sessionKeyValidatorAddr = address(sessionKeyValidator);
        userOp.nonce = uint256(uint160(sessionKeyValidatorAddr)) << 96;
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
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
            IERC20.transferFrom.selector,
            uint256(1 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct invalid selector user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(2 ether)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(erc20), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        address sessionKeyValidatorAddr = address(sessionKeyValidator);
        userOp.nonce = uint256(uint160(sessionKeyValidatorAddr)) << 96;
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_usingExecuteSingle() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        erc20.mint(address(mew), 10 ether);
        erc20.approve(address(mew), 5 ether);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(5 ether)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(erc20), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);
        assertEq(erc20.balanceOf(address(bob)), 5 ether);
    }

    function test_usingExecuteBatch() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        erc20.mint(address(mew), 10 ether);
        erc20.approve(address(mew), 10 ether);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(2 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(2 ether)
        );
        // Construct Executions - x5 of 2 ether each
        Execution[] memory executions = new Execution[](5);
        Execution memory executionData = Execution({
            target: address(erc20),
            value: 0,
            callData: data
        });
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i] = executionData;
        }
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);
        assertEq(erc20.balanceOf(address(bob)), 10 ether);
    }

    function test_usingMultipleSessionKeys() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        // Setup Session Keys
        address approvalSessionKeyAddr;
        uint256 approvalSessionKeyPrivate;
        address transferSessionKeyAddr;
        uint256 transferSessionKeyPrivate;
        (approvalSessionKeyAddr, approvalSessionKeyPrivate) = makeAddrAndKey(
            "approval_session_key"
        );
        (transferSessionKeyAddr, transferSessionKeyPrivate) = makeAddrAndKey(
            "transfer_session_key"
        );
        // ERC20 mint
        erc20.mint(address(mew), 10 ether);
        // Enable valid sessions
        // Session 1 - approve
        bytes memory approvalSessionData = abi.encodePacked(
            approvalSessionKeyAddr,
            address(erc20),
            IERC20.approve.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(approvalSessionData);
        // Session 2 - transfer
        bytes memory transferSessionData = abi.encodePacked(
            transferSessionKeyAddr,
            address(erc20),
            IERC20.transfer.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(transferSessionData);
        // Construct user op data
        // Approve
        bytes memory approvalData = abi.encodeWithSelector(
            IERC20.approve.selector,
            address(mew),
            uint256(5 ether)
        );
        // Transfer
        bytes memory transferData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            address(bob),
            uint256(2 ether)
        );
        // Construct UserOp.calldatas
        bytes memory approvalCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(
                    address(erc20),
                    uint256(0),
                    approvalData
                )
            )
        );
        bytes memory transferCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(
                    address(erc20),
                    uint256(0),
                    transferData
                )
            )
        );
        // First UserOp - Approve
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            approvalCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            approvalSessionKeyPrivate,
            hash
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);
        // Second UserOp - Transfer
        userOp = entrypoint.fillUserOp(address(mew), transferCalldata);
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        hash = entrypoint.getUserOpHash(userOp);
        (v, r, s) = vm.sign(transferSessionKeyPrivate, hash);
        signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        // Validation should succeed
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);
        assertEq(erc20.balanceOf(address(bob)), 2 ether);
    }

    function test_fail_differentSessionKeyAsSigner() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        erc20.mint(address(mew), 10 ether);
        erc20.approve(address(mew), 5 ether);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Enable another session to act as signer (use transfer instead of transferFrom)
        bytes memory anotherSessionData = abi.encodePacked(
            sessionKey1Addr,
            address(erc20),
            IERC20.transfer.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(anotherSessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(5 ether)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(erc20), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKey1Private, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Validation should fail - signed with different valid session key
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_fail_sessionSignedByOwnerEOA() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        erc20.mint(address(mew), 10 ether);
        erc20.approve(address(mew), 5 ether);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(5 ether)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(erc20), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner1Key, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Validation should fail - signed with different valid session key
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_fail_sessionSignedByInvalidKey() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        erc20.mint(address(mew), 10 ether);
        erc20.approve(address(mew), 5 ether);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(5 ether)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(erc20), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKey1Private, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Validation should fail - signed with different valid session key
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_usingWeiAmounts() public {
        // Test for successful transfer for 100000000000000 wei (0.0001 ether)
        // Test for failing transfer for 100000000000001 wei
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        erc20.mint(address(mew), 10 ether);
        erc20.approve(address(mew), 5 ether);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(100000000000000),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(100000000000000)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(erc20), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);
        assertEq(erc20.balanceOf(address(bob)), 100000000000000);
        // Test for invalid Wei amount - should revert
        // Construct user op data
        data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(100000000000001)
        );
        userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(erc20), uint256(0), data)
            )
        );
        userOp = entrypoint.fillUserOp(address(mew), userOpCalldata);
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        hash = entrypoint.getUserOpHash(userOp);
        (v, r, s) = vm.sign(sessionKeyPrivate, hash);
        signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        // Validation should fail due to exceeding spending limit
        userOps[0] = userOp;
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_usingTestUSDC() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        // Mint 10 USDC to MEW
        usdc.mint(address(mew), 10000000);
        assertEq(usdc.balanceOf(address(mew)), 10000000);
        usdc.approve(address(mew), 10000000);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(usdc),
            IERC20.transferFrom.selector,
            uint256(10000000),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(10000000)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(usdc), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);
        assertEq(usdc.balanceOf(address(bob)), 10000000);
    }

    function test_fail_usingTestUSDC() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        // Mint 10 USDC to MEW
        usdc.mint(address(mew), 10000000);
        usdc.approve(address(mew), 10000000);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(usdc),
            IERC20.transferFrom.selector,
            uint256(10000000),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(10000001)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(usdc), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        // Validation should fail - over spend limit
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_usingExecuteBatchLastExecBad() public {
        mew = setupMEWWithSessionKeys();
        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        // Mint and approve more than required for batch tx
        erc20.mint(address(mew), 11 ether);
        erc20.approve(address(mew), 11 ether);
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(erc20),
            IERC20.transferFrom.selector,
            uint256(2000000000000000000),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        sessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(2000000000000000000)
        );
        Execution[] memory executions = new Execution[](5);
        Execution memory executionData = Execution({
            target: address(erc20),
            value: 0,
            callData: data
        });
        for (uint256 i = 0; i < 4; i++) {
            executions[i] = executionData;
        }
        // Construct bad data for last tx in batch
        bytes memory badData = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            uint256(2000000000000000001)
        );
        Execution memory badExecutionData = Execution({
            target: address(erc20),
            value: 0,
            callData: badData
        });
        executions[4] = badExecutionData;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        // Validation should fail - last exec in batch exceeds spending limit
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }
}
