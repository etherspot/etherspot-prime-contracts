// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../src/modular-etherspot-wallet/modules/validators/TokenLockSessionKeyValidator.sol";
import "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import "../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import "../../../src/modular-etherspot-wallet/test/TestUSDC.sol";
import "../../../src/modular-etherspot-wallet/test/TestDAI.sol";
import "../../../src/modular-etherspot-wallet/test/TestUNI.sol";
import "../../../account-abstraction/contracts/core/Helpers.sol";
import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {VALIDATION_FAILED} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../TestAdvancedUtils.t.sol";
import "../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";

using ERC4337Utils for IEntryPoint;

contract TokenLockSessionKeyValidatorTest is TestAdvancedUtils {
    using ECDSA for bytes32;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                  VARIABLES               */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    ModularEtherspotWallet mew;
    TokenLockSessionKeyValidator tokenLockSessionKeyValidator;
    TestERC20 erc20;
    TestUSDC usdc;
    TestDAI dai;
    TestUNI uni;

    address alice;
    uint256 aliceKey;
    address bob;
    uint256 bobKey;
    address solver;
    uint256 solverKey;
    address payable beneficiary;
    address sessionKeyAddr;
    uint256 sessionKeyPrivate;
    address sessionKey1Addr;
    uint256 sessionKey1Private;
    address invalidSessionKey;
    address[] tokens;
    uint256[] amounts;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   EVENTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    event TLSKV_ModuleInstalled(address wallet);
    event TLSKV_ModuleUninstalled(address wallet);
    event TLSKV_SessionKeyEnabled(address sessionKey, address wallet);
    event TLSKV_SessionKeyDisabled(address sessionKey, address wallet);
    event TLSKV_SessionKeyPaused(address sessionKey, address wallet);
    event TLSKV_SessionKeyUnpaused(address sessionKey, address wallet);

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*             HELPER FUNCTIONS              */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function _getPrevValidator(
        address _validator
    ) internal view returns (address) {
        (address[] memory validators, ) = mew.getValidatorPaginated(
                address(0x1),
                10
            );
        // Presuming that wallet wont have gt 20 different validators installed
        for (uint256 i = 1; i < 20; i++) {
            if (validators[i] == _validator) {
                return validators[i - 1];
            }
        }
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    SETUP                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function setUp() public override {
        super.setUp();
        tokenLockSessionKeyValidator = new TokenLockSessionKeyValidator();
        erc20 = new TestERC20();
        usdc = new TestUSDC();
        dai = new TestDAI();
        uni = new TestUNI();

        tokens = new address[](3);
        tokens[0] = address(usdc);
        tokens[1] = address(dai);
        tokens[2] = address(uni);

        amounts = new uint256[](3);
        amounts[0] = 100 * 10**6;
        amounts[1] = 200 * 10**18;
        amounts[2] = 300 * 10**18;

        (sessionKeyAddr, sessionKeyPrivate) = makeAddrAndKey("session_key");
        (sessionKey1Addr, sessionKey1Private) = makeAddrAndKey("session_key_1");
        (invalidSessionKey, ) = makeAddrAndKey("invalid_session_key");
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
        (solver, solverKey) = makeAddrAndKey("solver");
        beneficiary = payable(address(makeAddr("beneficiary")));
        vm.deal(beneficiary, 1 ether);
    }

    function setupMEWWithTokenLockSessionKeyValidator() public returns (ModularEtherspotWallet) {
        mew = setupMEW();

        vm.startPrank(owner1);
        // Install another tokenLockSessionKeyValidator module for total of 3
        Execution[] memory batchCall1 = new Execution[](1);
        batchCall1[0].target = address(mew);
        batchCall1[0].value = 0;
        batchCall1[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(tokenLockSessionKeyValidator),
            hex""
        );
        // Check emitted event
        vm.expectEmit(false, false, false, true);
        emit TLSKV_ModuleInstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall1);

        Execution[] memory batchCall0 = new Execution[](1);
        batchCall0[0].target = address(mew);
        batchCall0[0].value = 0;
        batchCall0[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(defaultValidator),
            hex""
        );

        defaultExecutor.execBatch(IERC7579Account(mew), batchCall0);

        // Should be 3 Validator modules installed
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(tokenLockSessionKeyValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        
        vm.stopPrank();

        return mew;
    }

    function setup_sessionkey(ModularEtherspotWallet modularWallet, bytes4 functionSelector) public returns (address, ITokenLockSessionKeyValidator.SessionData memory) {
        vm.startPrank(address(modularWallet));

        usdc.mint(address(modularWallet), amounts[0]);
        assertEq(usdc.balanceOf(address(modularWallet)), amounts[0]);
        usdc.approve(address(bob), amounts[0]);
        usdc.approve(address(modularWallet), amounts[0]);

        dai.mint(address(modularWallet), amounts[1]);
        assertEq(dai.balanceOf(address(modularWallet)), amounts[1]);
        dai.approve(address(bob), amounts[1]);

        uni.mint(address(modularWallet), amounts[2]);
        assertEq(uni.balanceOf(address(modularWallet)), amounts[2]);
        uni.approve(address(bob), amounts[2]);

        uint48 validAfter = uint48(block.timestamp);
        uint48 validUntil = uint48(block.timestamp + 1 days);

        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            solver,
            functionSelector,
            validAfter,
            validUntil,
            tokens.length,
            tokens,
            amounts.length,
            amounts
        );

        tokenLockSessionKeyValidator.enableSessionKey(sessionData);
        ITokenLockSessionKeyValidator.SessionData memory sessionDataQueried = tokenLockSessionKeyValidator.getSessionKeyData(sessionKeyAddr);
        assertEq(tokenLockSessionKeyValidator.getAssociatedSessionKeys().length, 1);
        assertEq(sessionDataQueried.validUntil, validUntil);
        assertEq(sessionDataQueried.validAfter, validAfter);
        assertEq(sessionDataQueried.funcSelector, functionSelector);
        assertEq(sessionDataQueried.tokens.length, tokens.length);
        assertEq(sessionDataQueried.amounts.length, amounts.length);
        assertEq(sessionDataQueried.solverAddress, solver);
        assertTrue(sessionDataQueried.live);
        vm.stopPrank();

        return (sessionKeyAddr, sessionDataQueried);
    }

    function setup_disableSessionKey(ModularEtherspotWallet modularWallet, address sessionKey) public {
        vm.startPrank(address(modularWallet));

        vm.expectEmit(true, true, true, true);
        emit TLSKV_SessionKeyDisabled(sessionKey, address(modularWallet));
        tokenLockSessionKeyValidator.disableSessionKey(sessionKey);

        ITokenLockSessionKeyValidator.SessionData memory sessionData = tokenLockSessionKeyValidator.getSessionKeyData(sessionKey);

        assertEq(sessionData.validUntil, 0);
        assertEq(sessionData.validAfter, 0);
        assertEq(sessionData.funcSelector, bytes4(0));
        assertEq(sessionData.tokens.length, 0);
        assertEq(sessionData.amounts.length, 0);
        
        vm.stopPrank();
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    TESTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function test_install_TKSKV_Module() public {
        mew = setupMEWWithTokenLockSessionKeyValidator();
        assertTrue(mew.isModuleInstalled(1, address(tokenLockSessionKeyValidator), ""));
    }

    function test_Uninstall_TKSKV_Module() public {
        mew = setupMEWWithTokenLockSessionKeyValidator();
        setup_sessionkey(mew, IERC20.transfer.selector);

        vm.startPrank(address(mew));
       
        assertEq(tokenLockSessionKeyValidator.getAssociatedSessionKeys().length, 1);

        // Get previous tokenLockSessionKeyValidator to pass into uninstall (required for linked list)
        address prevValidator = _getPrevValidator(address(tokenLockSessionKeyValidator));
        // Uninstall session key tokenLockSessionKeyValidator
        Execution[] memory batchCall2 = new Execution[](1);
        batchCall2[0].target = address(mew);
        batchCall2[0].value = 0;
        batchCall2[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.uninstallModule.selector,
            uint256(1),
            address(tokenLockSessionKeyValidator),
            abi.encode(prevValidator, hex"")
        );
        // Check emitted event
        vm.expectEmit(false, false, false, true);
        emit TLSKV_ModuleUninstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall2);
        // Check session key tokenLockSessionKeyValidator is uninstalled
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertFalse(mew.isModuleInstalled(1, address(tokenLockSessionKeyValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        assertFalse(tokenLockSessionKeyValidator.isInitialized(address(mew)));
        assertEq(tokenLockSessionKeyValidator.getAssociatedSessionKeys().length, 0);
        vm.stopPrank();
    }

    function test_pass_TLSKV_enableSessionKey() public {
        mew = setupMEWWithTokenLockSessionKeyValidator();
        setup_sessionkey(mew, IERC20.transfer.selector);
    }

    function test_pass_TLSKV_disableSessionKey() public {
        mew = setupMEWWithTokenLockSessionKeyValidator();
        (address sessionKey, ) = setup_sessionkey(mew, IERC20.transfer.selector);
        setup_disableSessionKey(mew, sessionKey);
    }

    function test_pass_TLSKV_toggleSessionKeyPause() public {
        mew = setupMEWWithTokenLockSessionKeyValidator();
        (address sessionKey, ITokenLockSessionKeyValidator.SessionData memory sessionData) = setup_sessionkey(mew, IERC20.transfer.selector);
        vm.startPrank(address(mew));

        vm.expectEmit(true, true, true, true);
        emit TLSKV_SessionKeyPaused(sessionKey, address(mew));
        tokenLockSessionKeyValidator.toggleSessionKeyPause(sessionKey);
        ITokenLockSessionKeyValidator.SessionData memory sessionDataAfterToggle = tokenLockSessionKeyValidator.getSessionKeyData(sessionKey);
        assertFalse(sessionDataAfterToggle.live);

        vm.expectEmit(true, true, true, true);
        emit TLSKV_SessionKeyUnpaused(sessionKey, address(mew));
        tokenLockSessionKeyValidator.toggleSessionKeyPause(sessionKey);
        sessionDataAfterToggle = tokenLockSessionKeyValidator.getSessionKeyData(sessionKey);
        assertTrue(sessionDataAfterToggle.live);
        vm.stopPrank();
    }

    function test_fail_TLSKV_toggleSessionKeyPause() public {
        mew = setupMEWWithTokenLockSessionKeyValidator();
        vm.startPrank(address(mew));

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenLockSessionKeyValidator.TLSKV_SessionKeyDoesNotExist.selector,
                invalidSessionKey
            )
        );
        tokenLockSessionKeyValidator.toggleSessionKeyPause(invalidSessionKey);
        vm.stopPrank();
    }


    function test_pass_TLSKV_SessionKeyParams() public {

        mew = setupMEWWithTokenLockSessionKeyValidator();
        (address sessionKey, ITokenLockSessionKeyValidator.SessionData memory sessionData) = setup_sessionkey(mew, IERC20.transferFrom.selector);

        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            amounts[0]
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

        vm.startPrank(address(mew));

        userOp.nonce = getNonce(address(mew), address(tokenLockSessionKeyValidator));
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

        assertTrue(tokenLockSessionKeyValidator.validateSessionKeyParams(sessionKey, userOp));
        
        vm.stopPrank();
    }

    function test_pass_TLSKV_ValidateUserOp() public {

        mew = setupMEWWithTokenLockSessionKeyValidator();
        (address sessionKey, ITokenLockSessionKeyValidator.SessionData memory sessionDataStruct) = setup_sessionkey(mew, IERC20.transferFrom.selector);

        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            amounts[0]
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

        vm.startPrank(address(mew));

        userOp.nonce = getNonce(address(mew), address(tokenLockSessionKeyValidator));
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

        uint256 validationData = tokenLockSessionKeyValidator.validateUserOp(userOp, hash);

        uint256 expectedValidationData = _packValidationData(false, sessionDataStruct.validUntil, sessionDataStruct.validAfter);
        assertEq(validationData, expectedValidationData);
        
        vm.stopPrank();
    }

    function test_fail_TLSKV_validateUserOp_invalidFunctionSelector() public {
        mew = setupMEWWithTokenLockSessionKeyValidator();
        setup_sessionkey(mew, IERC20.transfer.selector);

        vm.startPrank(address(mew));
        // Construct invalid selector user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            100 * 10**6
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
        address tokenLockSessionKeyValidatorAddr = address(tokenLockSessionKeyValidator);
        userOp.nonce = uint256(uint160(tokenLockSessionKeyValidatorAddr)) << 96;
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        uint256 validationData = tokenLockSessionKeyValidator.validateUserOp(userOp, hash);
        assertEq(validationData, VALIDATION_FAILED);
        vm.stopPrank();
    }

    function test_fail_TLSKV_sessionSignedByInvalidKey() public {
        mew = setupMEWWithTokenLockSessionKeyValidator();
        setup_sessionkey(mew, IERC20.transferFrom.selector);

        vm.startPrank(address(mew));
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            100 * 10**6
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

        userOp.nonce = getNonce(address(mew), address(tokenLockSessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            owner1Key,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;

        uint256 validationData = tokenLockSessionKeyValidator.validateUserOp(userOp, hash);
        assertEq(validationData, VALIDATION_FAILED);

        vm.stopPrank();
    }

    function test_pass_TLSKV_E2E_handleUserOp() public {
        mew = setupMEWWithTokenLockSessionKeyValidator();
        (address sessionKey, ITokenLockSessionKeyValidator.SessionData memory sessionData) = setup_sessionkey(mew, IERC20.transferFrom.selector);

        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            amounts[0]
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

        userOp.nonce = getNonce(address(mew), address(tokenLockSessionKeyValidator));
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

        vm.startPrank(address(mew));

        entrypoint.handleOps(userOps, beneficiary);
        assertEq(usdc.balanceOf(address(bob)), amounts[0]);
    }
}
