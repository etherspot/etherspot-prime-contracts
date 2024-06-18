// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../src/modular-etherspot-wallet/modules/validators/SessionKeyValidator.sol";
import "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import "../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import "../../../src/modular-etherspot-wallet/modules/executors/ERC20Actions.sol";
import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {VALIDATION_FAILED} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../TestAdvancedUtils.t.sol";
import "../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";

using ERC4337Utils for IEntryPoint;

contract GenericSessionKeyValidatorTest is TestAdvancedUtils {
    using ECDSA for bytes32;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                  VARIABLES               */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    uint256 mainnetFork;

    ModularEtherspotWallet mew;
    SessionKeyValidator validator;
    TestERC20 erc20;
    ERC20Actions erc20Action;

    address alice;
    uint256 aliceKey;
    address bob;
    uint256 bobKey;
    address payable beneficiary;
    address sessionKeyAddr;
    uint256 sessionKeyPrivate;
    address sessionKey1Addr;
    uint256 sessionKey1Private;
    address dummyTarget;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   EVENTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    event SKV_ModuleInstalled(address wallet);
    event SKV_ModuleUninstalled(address wallet);
    event SKV_SessionKeyEnabled(address sessionKey, address wallet);
    event SKV_SessionKeyDisabled(address sessionKey, address wallet);
    event SKV_SessionKeyPaused(address sessionKey, address wallet);
    event SKV_SessionKeyUnpaused(address sessionKey, address wallet);

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
        mainnetFork = vm.createFork(vm.envString("ETHEREUM_RPC_URL"));
        validator = new SessionKeyValidator();
        (sessionKeyAddr, sessionKeyPrivate) = makeAddrAndKey("session_key");
        (sessionKey1Addr, sessionKey1Private) = makeAddrAndKey("session_key_1");
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
        dummyTarget = address(makeAddr("dummy_target"));
        beneficiary = payable(address(makeAddr("beneficiary")));
        vm.deal(beneficiary, 1 ether);
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    TESTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function test_selectFork() public {
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
    }

    function test_installModule() public {
        mew = setupMEW();
        vm.startPrank(owner1);
        // install another validator module for total of 3
        Execution[] memory batchCall1 = new Execution[](1);
        batchCall1[0].target = address(mew);
        batchCall1[0].value = 0;
        batchCall1[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(genericSessionKeyValidator),
            hex""
        );
        // check emitted event
        vm.expectEmit(false, false, false, true);
        emit SKV_ModuleInstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall1);
        // should be 3 validator modules installed
        assertTrue(
            mew.isModuleInstalled(1, address(genericSessionKeyValidator), "")
        );
    }

    function test_uninstallModule() public {
        mew = setupMEWWithGenericSessionKeys();
        vm.startPrank(address(mew));
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
        assertTrue(
            mew.isModuleInstalled(1, address(genericSessionKeyValidator), "")
        );
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        // check associated session keys == 1
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            erc20.approve.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        genericSessionKeyValidator.enableSessionKey(sessionData);
        assertEq(
            genericSessionKeyValidator.getAssociatedSessionKeys().length,
            1
        );
        // get previous validator to pass into uninstall
        // required for linked list
        address prevValidator = _getPrevValidator(
            address(genericSessionKeyValidator)
        );
        // uninstall session key validator
        Execution[] memory batchCall2 = new Execution[](1);
        batchCall2[0].target = address(mew);
        batchCall2[0].value = 0;
        batchCall2[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.uninstallModule.selector,
            uint256(1),
            address(genericSessionKeyValidator),
            abi.encode(prevValidator, hex"")
        );
        // check emitted event
        vm.expectEmit(false, false, false, true);
        emit SKV_ModuleUninstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall2);
        // check session key validator is uninstalled
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertFalse(
            mew.isModuleInstalled(1, address(genericSessionKeyValidator), "")
        );
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        assertFalse(genericSessionKeyValidator.isInitialized(address(mew)));
        assertEq(
            genericSessionKeyValidator.getAssociatedSessionKeys().length,
            0
        );
        vm.stopPrank();
    }

    function test_pass_enableSessionKey() public {
        vm.startPrank(alice);
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        // check emitted event
        vm.expectEmit(false, false, false, true);
        emit SKV_SessionKeyEnabled(sessionKeyAddr, address(alice));
        validator.enableSessionKey(sessionData);
        // Session should be enabled
        assertFalse(
            validator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
        vm.stopPrank();
    }

    function test_fail_enableSessionKey_InvalidSessionKey_SessionKeyZeroAddress()
        public
    {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            address(0),
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidSessionKey.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_SessionKeyAlreadyExists() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyAlreadyExists.selector,
                sessionKeyAddr
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_InvalidTarget() public {
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
                SessionKeyValidator.SKV_InvalidTarget.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_InvalidFunctionSelector() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            bytes4(0),
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidFunctionSelector.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_InvalidSpendingLimit() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(0),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidSpendingLimit.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_InvalidDuration() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp),
            uint48(block.timestamp)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidDuration.selector,
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
            dummyTarget,
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
        // check emitted event
        vm.expectEmit(false, false, false, true);
        emit SKV_SessionKeyDisabled(sessionKeyAddr, address(alice));

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
            dummyTarget,
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
            dummyTarget,
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

    function test_pass_toggleSessionKeyPause() public {
        // Enable session
        vm.startPrank(alice);
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
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
        emit SKV_SessionKeyPaused(sessionKeyAddr, alice);
        validator.toggleSessionKeyPause(sessionKeyAddr);
        // Session should now be disabled
        assertTrue(validator.checkSessionKeyPaused(sessionKeyAddr));
        vm.expectEmit(false, false, false, true);
        emit SKV_SessionKeyUnpaused(sessionKeyAddr, alice);
        validator.toggleSessionKeyPause(sessionKeyAddr);
        vm.stopPrank();
    }

    function test_pass_getAssociatedSessionKeys() public {
        bytes memory sessionData1 = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        bytes memory sessionData2 = abi.encodePacked(
            sessionKey1Addr,
            dummyTarget,
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
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            validAfter,
            validUntil
        );

        validator.enableSessionKey(sessionData);
        SessionKeyValidator.GenericSessionData memory data = validator
            .getSessionKeyData(sessionKeyAddr);
        assertEq(data.target, dummyTarget);
        assertEq(data.selector, IERC20.transferFrom.selector);
        assertEq(data.validAfter, validAfter);
        assertEq(data.validUntil, validUntil);
    }

    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////

    function test_pass_validateUserOp() public {
        // start fork
        vm.selectFork(mainnetFork);

        mew = setupMEWWithGenericSessionKeys();
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
            dummyTarget,
            ERC20Actions.transferERC20Action.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        genericSessionKeyValidator.enableSessionKey(sessionData);
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
        userOp.nonce = getNonce(
            address(mew),
            address(genericSessionKeyValidator)
        );
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;

        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);
        assertEq(erc20.balanceOf(address(bob)), 5 ether);
    }

    function test_fail_validateUserOp_invalidSessionKey() public {
        mew = setupMEWWithGenericSessionKeys();
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
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );

        genericSessionKeyValidator.enableSessionKey(sessionData);
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
        userOp.nonce = getNonce(
            address(mew),
            address(genericSessionKeyValidator)
        );
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Validation should fail
        genericSessionKeyValidator.disableSessionKey(sessionKeyAddr);
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA23 reverted",
                abi.encodeWithSignature("SKV_InvalidSessionKey()")
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_fail_validateUserOp_invalidFunctionSelector() public {
        mew = setupMEWWithGenericSessionKeys();
        vm.startPrank(address(mew));
        // Construct and enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transfer.selector,
            uint256(5 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        genericSessionKeyValidator.enableSessionKey(sessionData);
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
        address sessionKeyValidatorAddr = address(genericSessionKeyValidator);
        userOp.nonce = uint256(uint160(sessionKeyValidatorAddr)) << 96;
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA23 reverted",
                abi.encodeWithSelector(
                    SessionKeyValidator.SKV_UnsupportedSelector.selector,
                    IERC20.transferFrom.selector
                )
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }
}
