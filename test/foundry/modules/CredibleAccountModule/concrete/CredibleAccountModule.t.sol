// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {CredibleAccountModule as CAM} from "../../../../../src/modular-etherspot-wallet/modules/validators/CredibleAccountModule.sol";
import {ICredibleAccountModule as ICAM} from "../../../../../src/modular-etherspot-wallet/interfaces/ICredibleAccountModule.sol";
import {HookMultiPlexerLib as HMPL} from "../../../../../src/modular-etherspot-wallet/modules/hooks/multiplexer/HookMultiPlexerLib.sol";
import "../../../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {SessionData, TokenData} from "../../../../../src/modular-etherspot-wallet/common/Structs.sol";
import {HookType} from "../../../../../src/modular-etherspot-wallet/modules/hooks/multiplexer/DataTypes.sol";
import {CredibleAccountModuleTestUtils as LocalTestUtils} from "../utils/CredibleAccountModuleTestUtils.sol";
import {TestWETH} from "../../../../../src/modular-etherspot-wallet/test/TestWETH.sol";
import {TestUniswapV2} from "../../../../../src/modular-etherspot-wallet/test/TestUniswapV2.sol";
import "../../../../../account-abstraction/contracts/core/Helpers.sol";
import {PackedUserOperation} from "../../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {VALIDATION_FAILED, MODULE_TYPE_HOOK, MODULE_TYPE_VALIDATOR} from "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

using ERC4337Utils for IEntryPoint;

contract CredibleAccountModule_Concrete_Test is LocalTestUtils {
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CredibleAccountModule_ModuleInstalled(address wallet);
    event CredibleAccountModule_ModuleUninstalled(address wallet);
    event CredibleAccountModule_SessionKeyEnabled(
        address sessionKey,
        address wallet
    );
    event CredibleAccountModule_SessionKeyDisabled(
        address sessionKey,
        address wallet
    );

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                       PUBLIC/EXTERNAL TESTING
    //////////////////////////////////////////////////////////////*/

    // Test: Verify that the CredibleAccountModule module can be installed
    // as both validator and hook modules
    function test_installModule() public {
        // Set up the test environment with CredibleAccountModule
        _testSetup();
        // Verify that the module is installed
        assertTrue(
            mew.isModuleInstalled(
                1,
                address(credibleAccountModule),
                "CredibleAccountModule module should be installed"
            )
        );
        assertEq(
            mew.getActiveHook(),
            address(hookMultiPlexer),
            "Active hook should be HookMultiPlexer"
        );
        assertEq(
            hookMultiPlexer.getHooks(address(mew))[0],
            address(credibleAccountModule)
        );
    }

    function test_onInstall_validator_viaUserOp_single() public {
        mew = setupMEWWithEmptyHookMultiplexer();
        (alice, aliceKey) = makeAddrAndKey("alice");
        (sessionKey, sessionKeyPrivateKey) = makeAddrAndKey("sessionKey");
        vm.deal(beneficiary, 1 ether);
        // Add CAM as subHook first
        _addCredibleAccountModuleAsSubHook();
        // Verify subHook install
        assertEq(
            hookMultiPlexer.getHooks(address(mew))[0],
            address(credibleAccountModule)
        );
        vm.startPrank(address(mew));
        bytes memory installValidatorData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(credibleAccountModule),
            abi.encode(MODULE_TYPE_VALIDATOR)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(mew), 0, installValidatorData)
            )
        );
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperationWithoutProof(
                address(mew),
                userOpCalldata,
                owner1Key
            );
        // Execute the user operation
        _executeUserOperation(userOp);
        // Verify
        assertTrue(
            mew.isModuleInstalled(
                1,
                address(credibleAccountModule),
                "CredibleAccountModule module should be installed"
            )
        );
    }

    function test_onInstall_validatorAndHook_viaUserOp_batch() public {
        mew = setupMEWWithEmptyHookMultiplexer();
        (alice, aliceKey) = makeAddrAndKey("alice");
        (sessionKey, sessionKeyPrivateKey) = makeAddrAndKey("sessionKey");
        vm.deal(beneficiary, 1 ether);
        vm.startPrank(address(mew));
        Execution[] memory batch = new Execution[](2);
        batch[0].target = address(hookMultiPlexer);
        batch[0].value = 0;
        batch[0].callData = abi.encodeWithSelector(
            hookMultiPlexer.addHook.selector,
            address(credibleAccountModule),
            HookType.GLOBAL
        );
        batch[1].target = address(mew);
        batch[1].value = 0;
        batch[1].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(credibleAccountModule),
            abi.encode(MODULE_TYPE_VALIDATOR)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(batch))
        );
        (
            ,
            PackedUserOperation memory userOp
        ) = _createUserOperationWithoutProof(
                address(mew),
                userOpCalldata,
                owner1Key
            );

        // Execute the user operation
        _executeUserOperation(userOp);
        // Verify that the module is installed
        assertTrue(
            mew.isModuleInstalled(
                1,
                address(credibleAccountModule),
                "CredibleAccountModule module should be installed"
            )
        );
        assertEq(
            hookMultiPlexer.getHooks(address(mew))[0],
            address(credibleAccountModule)
        );
    }

    // Test: Verify that the CredibleAccountModule validator can be uninstalled
    // when all locked tokens have been claimed by the solver
    function test_uninstallModule_validator_allLockedTokensClaimed() public {
        // Set up the test environment with CredibleAccountModule
        _testSetup();
        // Enable session key
        _enableDefaultSessionKey();
        // Claim all tokens by solver
        _claimTokensBySolver(amounts[0], amounts[1], amounts[2]);
        // Get previous validator in linked list
        address prevValidator = _getPrevValidator(
            address(credibleAccountModule)
        );
        // Prepare uninstallation call
        Execution[] memory uninstallCall = new Execution[](1);
        uninstallCall[0].target = address(mew);
        uninstallCall[0].value = 0;
        uninstallCall[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.uninstallModule.selector,
            uint256(1),
            address(credibleAccountModule),
            abi.encode(
                prevValidator,
                abi.encode(MODULE_TYPE_VALIDATOR, address(mew))
            )
        );
        // Expect the uninstallation event to be emitted
        vm.expectEmit(false, false, false, true);
        emit CredibleAccountModule_ModuleUninstalled(address(mew));
        // Execute the uninstallation
        defaultExecutor.execBatch(IERC7579Account(mew), uninstallCall);
        // Verify that the module is uninstalled and session keys are removed
        assertTrue(
            mew.isModuleInstalled(
                1,
                address(ecdsaValidator),
                "MultipleOwnerECDSAValidator module should be installed"
            )
        );
        assertFalse(
            mew.isModuleInstalled(
                1,
                address(credibleAccountModule),
                "CredibleAccountModule validator should not be installed"
            )
        );
    }

    // Test: Verify that the CredibleAccountModule validator cannot be uninstalled
    // if locked tokens have not been claimed by the solver
    function test_uninstallModule_validator_revertWhen_lockedTokensNotClaimed()
        public
    {
        // Set up the test environment with CredibleAccountModule
        _testSetup();
        // Enable session key
        _enableDefaultSessionKey();
        // Get previous validator in linked list
        address prevValidator = _getPrevValidator(
            address(credibleAccountModule)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                CAM.CredibleAccountModule_LockedTokensNotClaimed.selector,
                sessionKey
            )
        );
        mew.uninstallModule(
            1,
            address(credibleAccountModule),
            abi.encode(
                prevValidator,
                abi.encode(MODULE_TYPE_VALIDATOR, address(mew))
            )
        );
        assertTrue(
            mew.isModuleInstalled(
                1,
                address(credibleAccountModule),
                "CredibleAccountModule validator should be installed"
            )
        );
    }

    // Test: Verify that the CredibleAccountModule hook can be uninstalled
    // when all locked tokens have been claimed by the solver
    // and validator is uninstalled
    function test_uninstallModule_hook_allLockedTokensClaimed() public {
        // Set up the test environment with CredibleAccountModule
        _testSetup();
        // Enable session key
        _enableDefaultSessionKey();
        // Claim all tokens by solver
        _claimTokensBySolver(amounts[0], amounts[1], amounts[2]);
        // Verify that the hook is installed via the multiplexer for the wallet
        assertEq(hookMultiPlexer.getHooks(address(mew)).length, 1);
        assertEq(
            hookMultiPlexer.getHooks(address(mew))[0],
            address(credibleAccountModule)
        );
        // Uninstall the validator module first
        // Get previous validator in linked list
        address prevValidator = _getPrevValidator(
            address(credibleAccountModule)
        );
        vm.expectEmit(true, true, false, false);
        emit ICAM.CredibleAccountModule_ModuleUninstalled(address(mew));
        mew.uninstallModule(
            1,
            address(credibleAccountModule),
            abi.encode(
                prevValidator,
                abi.encode(MODULE_TYPE_VALIDATOR, address(mew))
            )
        );
        // Remove the hook from the multiplexer
        hookMultiPlexer.removeHook(
            address(credibleAccountModule),
            HookType.GLOBAL
        );
        assertEq(
            mew.getActiveHook(),
            address(hookMultiPlexer),
            "HookMultiPlexer should be active hook"
        );
        // Verify wallet has no hooks installed via multiplexer
        assertEq(hookMultiPlexer.getHooks(address(mew)).length, 0);
    }

    // Test: Verify that the CredibleAccountModule hook can be uninstalled
    // when tokens partially claimed but session key has expired
    // and validator is uninstalled first
    function test_uninstallModule_hook_sessionKeyExpired() public {
        // Set up the test environment with CredibleAccountModule
        _testSetup();
        // Enable session key
        _enableDefaultSessionKey();
        // Warp to after session key expiration
        vm.warp(validUntil + 1);
        // Verify that the hook is installed via the multiplexer for the wallet
        assertEq(hookMultiPlexer.getHooks(address(mew)).length, 1);
        assertEq(
            hookMultiPlexer.getHooks(address(mew))[0],
            address(credibleAccountModule)
        );
        // Uninstall the validator module first
        // Get previous validator in linked list
        address prevValidator = _getPrevValidator(
            address(credibleAccountModule)
        );
        vm.expectEmit(true, true, false, false);
        emit ICAM.CredibleAccountModule_ModuleUninstalled(address(mew));
        mew.uninstallModule(
            1,
            address(credibleAccountModule),
            abi.encode(
                prevValidator,
                abi.encode(MODULE_TYPE_VALIDATOR, address(mew))
            )
        );
        // Remove the hook from the multiplexer
        hookMultiPlexer.removeHook(
            address(credibleAccountModule),
            HookType.GLOBAL
        );
        // Verify wallet has no hooks installed via multiplexer
        assertEq(hookMultiPlexer.getHooks(address(mew)).length, 0);
    }

    // Test: Verify that the CredibleAccountModule hook cannot be uninstalled
    // when validator is not uninstalled first
    function test_uninstallModule_hook_revertWhen_validatorIsInstalled()
        public
    {
        // Set up the test environment with CredibleAccountModule
        _testSetup();
        // Enable session key
        _enableDefaultSessionKey();
        // Try to remove the hook from the multiplexer
        vm.expectRevert(
            abi.encodeWithSelector(
                CAM.CredibleAccountModule_ValidatorExists.selector
            )
        );
        hookMultiPlexer.removeHook(
            address(credibleAccountModule),
            HookType.GLOBAL
        );
        // Verify that the hook is installed via the multiplexer for the wallet
        assertEq(hookMultiPlexer.getHooks(address(mew)).length, 1);
        assertEq(
            hookMultiPlexer.getHooks(address(mew))[0],
            address(credibleAccountModule)
        );
    }

    // Test: Verify that a session key can be enabled
    function test_enableSessionKey() public {
        // Set up the test environment and enable a session key
        _testSetup();
        vm.expectEmit(true, true, false, false);
        emit ICAM.CredibleAccountModule_SessionKeyEnabled(
            sessionKey,
            address(mew)
        );
        _enableDefaultSessionKey();
        // Verify that the session key is enabled
        assertEq(
            credibleAccountModule.getSessionKeysByWallet().length,
            1,
            "Session key should be enabled"
        );
        // Verify SessionData
        SessionData memory sessionData = credibleAccountModule
            .getSessionKeyData(sessionKey);
        assertEq(
            sessionData.validUntil,
            validUntil,
            "validUntil does not match expected"
        );
        assertEq(
            sessionData.validAfter,
            validAfter,
            "validAfter does not match expected"
        );
        // Verify LockedToken data for session key
        ICAM.LockedToken[] memory lockedTokens = credibleAccountModule
            .getLockedTokensForSessionKey(sessionKey);
        assertEq(
            lockedTokens.length,
            3,
            "Number of locked tokens does not match expected"
        );
        assertEq(
            lockedTokens[0].token,
            tokens[0],
            "The first locked token address does not match expected"
        );
        assertEq(
            lockedTokens[0].lockedAmount,
            amounts[0],
            "The first locked token locked amount does not match expected"
        );
        assertEq(
            lockedTokens[0].claimedAmount,
            0,
            "The first locked token claimed amount does not match expected"
        );
        assertEq(
            lockedTokens[1].token,
            tokens[1],
            "The second locked token address does not match expected"
        );
        assertEq(
            lockedTokens[1].lockedAmount,
            amounts[1],
            "The second locked token locked amount does not match expected"
        );
        assertEq(
            lockedTokens[1].claimedAmount,
            0,
            "The second locked token claimed amount does not match expected"
        );
        assertEq(
            lockedTokens[2].token,
            tokens[2],
            "The third locked token address does not match expected"
        );
        assertEq(
            lockedTokens[2].lockedAmount,
            amounts[2],
            "The third locked token locked amount does not match expected"
        );
        assertEq(
            lockedTokens[2].claimedAmount,
            0,
            "The third locked token claimed amount does not match expected"
        );
    }

    // Test: Enabling a session key with an invalid session key should revert
    function test_enableSessionKey_revertIf_invalidSesionKey() public {
        // Set up the test environment and enable a session key
        _testSetup();
        TokenData[] memory tokenAmounts = new TokenData[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            tokenAmounts[i] = TokenData(tokens[i], amounts[i]);
        }
        bytes memory sessionData = abi.encode(
            address(0),
            validAfter,
            validUntil,
            tokenAmounts
        );
        // Attempt to enable the session key
        vm.expectRevert(
            abi.encodeWithSelector(
                CAM.CredibleAccountModule_InvalidSessionKey.selector
            )
        );
        credibleAccountModule.enableSessionKey(sessionData);
    }

    // Test: Enabling a session key with an invalid validAfter should revert
    function test_enableSessionKey_revertIf_invalidValidAfter() public {
        // Set up the test environment and enable a session key
        _testSetup();
        TokenData[] memory tokenAmounts = new TokenData[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            tokenAmounts[i] = TokenData(tokens[i], amounts[i]);
        }
        bytes memory sessionData = abi.encode(
            sessionKey,
            uint48(0),
            validUntil,
            tokenAmounts
        );
        // Attempt to enable the session key
        vm.expectRevert(
            abi.encodeWithSelector(
                CAM.CredibleAccountModule_InvalidValidAfter.selector
            )
        );
        credibleAccountModule.enableSessionKey(sessionData);
    }

    // Test: Enabling a session key with an invalid validUntil should revert
    function test_enableSessionKey_revertIf_invalidValidUntil() public {
        // Set up the test environment and enable a session key
        _testSetup();
        // validUntil that is 0
        TokenData[] memory tokenAmounts = new TokenData[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            tokenAmounts[i] = TokenData(tokens[i], amounts[i]);
        }
        bytes memory sessionData = abi.encode(
            sessionKey,
            validAfter,
            uint48(0),
            tokenAmounts
        );
        // Attempt to enable the session key
        vm.expectRevert(
            abi.encodeWithSelector(
                CAM.CredibleAccountModule_InvalidValidUntil.selector,
                0
            )
        );
        credibleAccountModule.enableSessionKey(sessionData);
        // validUntil that is less than validAfter
        sessionData = abi.encode(
            sessionKey,
            validAfter,
            validAfter - 1,
            tokenAmounts
        );
        // Attempt to enable the session key
        vm.expectRevert(
            abi.encodeWithSelector(
                CAM.CredibleAccountModule_InvalidValidUntil.selector,
                validAfter - 1
            )
        );
        credibleAccountModule.enableSessionKey(sessionData);
    }

    // Test: Verify that a session key can be disabled
    function test_disableSessionKey() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        // Claim tokens by solver
        _claimTokensBySolver(amounts[0], amounts[1], amounts[2]);
        // Expect emit a session key disabled event
        vm.expectEmit(true, true, false, false);
        emit ICAM.CredibleAccountModule_SessionKeyDisabled(
            sessionKey,
            address(mew)
        );
        credibleAccountModule.disableSessionKey(sessionKey);
    }

    // Test: Verify that a session key can be disabled after it expires
    // regardless of whether tokens are locked
    function test_disableSessionKey_withLockedTokens_afterSessionExpires()
        public
    {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        // Warp to a time after the session key has expired
        vm.warp(validUntil + 1);
        // Expect emit a session key disabled event
        vm.expectEmit(true, true, false, false);
        emit ICAM.CredibleAccountModule_SessionKeyDisabled(
            sessionKey,
            address(mew)
        );
        credibleAccountModule.disableSessionKey(sessionKey);
    }

    // Test: Disabling a session key with an invalid session key should revert
    function test_disableSessionKey_revertIf_invalidSessionKey() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        // Claim tokens by solver
        _claimTokensBySolver(amounts[0], amounts[1], amounts[2]);
        // Attempt to disable the session key
        vm.expectRevert(
            abi.encodeWithSelector(
                CAM.CredibleAccountModule_SessionKeyDoesNotExist.selector,
                dummySessionKey
            )
        );
        credibleAccountModule.disableSessionKey(dummySessionKey);
    }

    // Test: Disabling a session key when tokens aren't claimed reverts
    function test_disableSessionKey_revertIf_TokensNotClaimed() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        // Attempt to disable the session key
        vm.expectRevert(
            abi.encodeWithSelector(
                CAM.CredibleAccountModule_LockedTokensNotClaimed.selector,
                sessionKey
            )
        );
        credibleAccountModule.disableSessionKey(sessionKey);
    }

    // Test: Should return all session kets associated with a wallet
    function test_getSessionKeysByWallet() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        address[] memory sessions = credibleAccountModule
            .getSessionKeysByWallet();
        assertEq(
            sessions.length,
            1,
            "There should be one session key associated with wallet"
        );
        assertEq(
            sessions[0],
            sessionKey,
            "The associated session key should be the expected one"
        );
    }

    // Test: Should return correct session key data
    function test_getSessionKeyData() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        SessionData memory sessionData = credibleAccountModule
            .getSessionKeyData(sessionKey);
        assertEq(
            sessionData.validAfter,
            validAfter,
            "validAfter should be the expected value"
        );
        assertEq(
            sessionData.validUntil,
            validUntil,
            "validUntil should be the expected value"
        );
    }

    // Test: Should return default values for non-existant session key
    function test_getSessionKeyData_nonExistantSession_returnsDefaultValues()
        public
    {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        SessionData memory sessionData = credibleAccountModule
            .getSessionKeyData(dummySessionKey);
        // All retrieved session data should be default values
        assertEq(
            sessionData.validAfter,
            0,
            "validAfter should be default value"
        );
        assertEq(
            sessionData.validUntil,
            0,
            "validUntil should be  default value"
        );
    }

    // Test: Should return correct locked tokens for session key
    function test_getLockedTokensForSessionKey() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        ICAM.LockedToken[] memory lockedTokens = credibleAccountModule
            .getLockedTokensForSessionKey(sessionKey);
        assertEq(
            lockedTokens.length,
            3,
            "Number of locked tokens does not match expected"
        );
        assertEq(
            lockedTokens[0].token,
            tokens[0],
            "The first locked token address does not match expected"
        );
        assertEq(
            lockedTokens[0].lockedAmount,
            amounts[0],
            "The first locked token locked amount does not match expected"
        );
        assertEq(
            lockedTokens[0].claimedAmount,
            0,
            "The first locked token claimed amount does not match expected"
        );
        assertEq(
            lockedTokens[1].token,
            tokens[1],
            "The second locked token address does not match expected"
        );
        assertEq(
            lockedTokens[1].lockedAmount,
            amounts[1],
            "The second locked token locked amount does not match expected"
        );
        assertEq(
            lockedTokens[1].claimedAmount,
            0,
            "The second locked token claimed amount does not match expected"
        );
        assertEq(
            lockedTokens[2].token,
            tokens[2],
            "The third locked token address does not match expected"
        );
        assertEq(
            lockedTokens[2].lockedAmount,
            amounts[2],
            "The third locked token locked amount does not match expected"
        );
        assertEq(
            lockedTokens[2].claimedAmount,
            0,
            "The third locked token claimed amount does not match expected"
        );
    }

    // Test: Should return cumulative locked balance for a token
    // over all wallet's session keys
    function test_tokenTotalLockedForWallet() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        // Enable another session key
        usdc.mint(address(mew), 10e6);
        TokenData[] memory newTokenData = new TokenData[](1);
        newTokenData[0] = TokenData(address(usdc), 10e6);
        bytes memory newSessionData = abi.encode(
            dummySessionKey,
            validAfter,
            validUntil,
            newTokenData
        );
        credibleAccountModule.enableSessionKey(newSessionData);
        uint256 totalUSDCLocked = credibleAccountModule
            .tokenTotalLockedForWallet(address(usdc));
        assertEq(
            totalUSDCLocked,
            amounts[0] + 10e6,
            "Expected USDC cumulative locked balance does not match expected amount"
        );
    }

    function test_cumulativeLockedForWallet() public {
        // Set up the test environment and enable a session key
        _testSetup();
        TestWETH weth = new TestWETH();
        _enableDefaultSessionKey();
        // Enable another session key
        uint256[4] memory newAmounts = [
            uint256(10e6),
            uint256(40e18),
            uint256(50e18),
            uint256(113e18)
        ];
        usdc.mint(address(mew), newAmounts[0]);
        dai.mint(address(mew), newAmounts[1]);
        uni.mint(address(mew), newAmounts[2]);
        vm.deal(address(mew), newAmounts[3]);
        weth.deposit{value: newAmounts[3]}();
        TokenData[] memory newTokenData = new TokenData[](tokens.length + 1);
        for (uint256 i; i < 3; ++i) {
            newTokenData[i] = TokenData(tokens[i], newAmounts[i]);
        }
        // Append WETH lock onto newTokenData
        newTokenData[3] = TokenData(address(weth), newAmounts[3]);
        bytes memory newSessionData = abi.encode(
            dummySessionKey,
            validAfter,
            validUntil,
            newTokenData
        );
        credibleAccountModule.enableSessionKey(newSessionData);
        // Get cumulative locked funds for wallet
        TokenData[] memory data = credibleAccountModule
            .cumulativeLockedForWallet();
        // Verify retrieved data matches expected
        assertEq(
            data[0].token,
            address(usdc),
            "First token address does not match expected (expected USDC)"
        );
        assertEq(
            data[0].amount,
            amounts[0] + newAmounts[0],
            "Cumulative USDC locked balance does not match expected amount"
        );
        assertEq(
            data[1].token,
            address(dai),
            "Second token address does not match expected (expected DAI)"
        );
        assertEq(
            data[1].amount,
            amounts[1] + newAmounts[1],
            "Cumulative DAI locked balance does not match expected amount"
        );

        assertEq(
            data[2].token,
            address(uni),
            "Third token address does not match expected (expected UNI)"
        );
        assertEq(
            data[2].amount,
            amounts[2] + newAmounts[2],
            "Cumulative UNI locked balance does not match expected amount"
        );
        assertEq(
            data[3].token,
            address(weth),
            "Fourth token address does not match expected (expected WETH)"
        );
        assertEq(
            data[3].amount,
            newAmounts[3],
            "Cumulative WETH locked balance does not match expected amount"
        );
    }

    // Test: Claimed session should return true
    function test_isSessionClaimed_true() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        // Claim tokens by solver
        _claimTokensBySolver(amounts[0], amounts[1], amounts[2]);
        assertTrue(credibleAccountModule.isSessionClaimed(sessionKey));
    }

    // Test: Unclaimed session should return false
    function test_isSessionClaimed_false() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableDefaultSessionKey();
        assertFalse(credibleAccountModule.isSessionClaimed(sessionKey));
    }

    // Test: Should return true on validator
    function test_isModuleType_validator_true() public {
        // Set up the test environment and enable a session key
        _testSetup();
        assertTrue(credibleAccountModule.isModuleType(1));
    }

    // Test: Should return true on hook
    function test_isModuleType_hook_true() public {
        // Set up the test environment and enable a session key
        _testSetup();
        assertTrue(credibleAccountModule.isModuleType(4));
    }

    // Test: Should always revert
    function test_isValidSignatureWithSender() public {
        // Set up the test environment and enable a session key
        _testSetup();
        vm.expectRevert(abi.encodeWithSelector(CAM.NotImplemented.selector));
        credibleAccountModule.isValidSignatureWithSender(
            address(alice),
            bytes32(0),
            bytes("0x")
        );
    }

    // Test: claiming all tokens (batch)
    function test_claimingTokens_batchExecute() public {
        // Set up the test environment
        _testSetup();
        // Get enableSessionKey UserOperation
        _enableDefaultSessionKey();
        // Claim tokens by solver
        _claimTokensBySolver(amounts[0], amounts[1], amounts[2]);
        // Check tokens are unlocked
        assertTrue(credibleAccountModule.isSessionClaimed(sessionKey));
    }

    // Test: claiming tokens with an amount
    // that exceeds the locked amount fails (batch)
    function test_claimingTokens_batchExecute_revertIf_claimExceedsLocked()
        public
    {
        // Set up the test environment
        _testSetup();
        // Enable session key
        _enableDefaultSessionKey();
        // Set up calldata batch
        bytes memory usdcData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            amounts[0]
        );
        bytes memory daiData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            amounts[1]
        );
        bytes memory uniData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            amounts[2] + 1
        );
        Execution[] memory batch = new Execution[](3);
        Execution memory usdcExec = Execution({
            target: address(usdc),
            value: 0,
            callData: usdcData
        });
        Execution memory daiExec = Execution({
            target: address(dai),
            value: 0,
            callData: daiData
        });
        Execution memory uniExec = Execution({
            target: address(uni),
            value: 0,
            callData: uniData
        });
        batch[0] = usdcExec;
        batch[1] = daiExec;
        batch[2] = uniExec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(batch))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(credibleAccountModule),
            sessionKeyPrivateKey
        );
        // Expect the operation to revert due to signature error
        // (claiming exceeds locked)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operation
        _executeUserOperation(userOp);
    }

    // Test: Should revert if the session key is expired
    // no tokens claimed yet
    // and solver tried to claim tokens
    function test_claimingTokens_batchExecute_revertIf_sessionKeyExpired()
        public
    {
        // Set up the test environment
        _testSetup();
        // Get enableSessionKey UserOperation
        _enableDefaultSessionKey();
        // Warp time to expire the session key
        vm.warp(validUntil + 1);
        // Claim tokens by solver
        bytes memory usdcData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            amounts[0]
        );
        bytes memory daiData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            amounts[1]
        );
        bytes memory uniData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            amounts[2]
        );
        Execution[] memory batch = new Execution[](3);
        Execution memory usdcExec = Execution({
            target: address(usdc),
            value: 0,
            callData: usdcData
        });
        Execution memory daiExec = Execution({
            target: address(dai),
            value: 0,
            callData: daiData
        });
        Execution memory uniExec = Execution({
            target: address(uni),
            value: 0,
            callData: uniData
        });
        batch[0] = usdcExec;
        batch[1] = daiExec;
        batch[2] = uniExec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(batch))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(credibleAccountModule),
            sessionKeyPrivateKey
        );
        // Expect the operation to revert due to signature error (expired session)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA22 expired or not due"
            )
        );
        // Attempt to execute the user operation
        _executeUserOperation(userOp);
    }

    // Test: Should revert if claiming tokens by solver
    // that dont match locked amounts
    function test_claimingTokens_doesNotMatchLockedAmounts() public {
        // Set up the test environment
        _testSetup();
        // Get enableSessionKey UserOperation
        _enableDefaultSessionKey();
        // Claim tokens by solver that dont match locked amounts
        bytes memory usdcData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            1e6
        );
        bytes memory daiData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            1e18
        );
        bytes memory uniData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            1e18
        );
        Execution[] memory batch = new Execution[](3);
        Execution memory usdcExec = Execution({
            target: address(usdc),
            value: 0,
            callData: usdcData
        });
        Execution memory daiExec = Execution({
            target: address(dai),
            value: 0,
            callData: daiData
        });
        Execution memory uniExec = Execution({
            target: address(uni),
            value: 0,
            callData: uniData
        });
        batch[0] = usdcExec;
        batch[1] = daiExec;
        batch[2] = uniExec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(batch))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(credibleAccountModule),
            sessionKeyPrivateKey
        );
        // Expect the operation to revert due to signature error (invalid amounts)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operation
        _executeUserOperation(userOp);
    }

    // Test: ERC20 transaction using amount that exceeds the
    // available unlocked balance fails (single)
    function test_transactingLockedTokens_revertIf_notEnoughUnlockedBalance_singleExecute()
        public
    {
        // Set up the test environment
        _testSetup();
        // Enable session key
        _enableDefaultSessionKey();
        // Mint extra tokens to wallet
        dai.mint(address(mew), 1e18);
        // Set up calldata batch
        // Invalid transaction as only 1 ether unlocked
        bytes memory daiData = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            2e18
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(dai), 0, daiData)
            )
        );
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                address(ecdsaValidator),
                owner1Key
            );
        // Expect the HookMultiPlexer.SubHookPostCheckError error to be emitted
        // wrapped in UserOperationRevertReason event
        vm.expectEmit(false, false, false, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOp.nonce,
            abi.encodeWithSelector(
                HMPL.SubHookPostCheckError.selector,
                address(credibleAccountModule)
            )
        );
        // Attempt to execute the user operation
        _executeUserOperation(userOp);
    }

    // Test: ERC20 transaction using amount that exceeds the
    // available unlocked balance fails (batch)
    function test_batchExecute_revertIf_transactingLockedTokens_otherValidator()
        public
    {
        // Set up the test environment
        _testSetup();
        // Enable session key
        _enableDefaultSessionKey();
        // Mint extra tokens to wallet
        usdc.mint(address(mew), 1e6);
        dai.mint(address(mew), 1e18);
        uni.mint(address(mew), 1e18);
        // Set up calldata batch
        bytes memory usdcData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            1e6
        );
        bytes memory daiData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            1e18
        );
        // Invalid transaction as only 1 ether unlocked
        bytes memory uniData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            2e18
        );
        Execution[] memory batch = new Execution[](3);
        Execution memory usdcExec = Execution({
            target: address(usdc),
            value: 0,
            callData: usdcData
        });
        Execution memory daiExec = Execution({
            target: address(dai),
            value: 0,
            callData: daiData
        });
        Execution memory uniExec = Execution({
            target: address(uni),
            value: 0,
            callData: uniData
        });
        batch[0] = usdcExec;
        batch[1] = daiExec;
        batch[2] = uniExec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(batch))
        );
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                address(ecdsaValidator),
                owner1Key
            );
        // Expect the HookMultiPlexer.SubHookPostCheckError error to be emitted
        // wrapped in UserOperationRevertReason event
        vm.expectEmit(false, false, false, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOp.nonce,
            abi.encodeWithSelector(
                HMPL.SubHookPostCheckError.selector,
                address(credibleAccountModule)
            )
        );
        // Attempt to execute the user operation
        _executeUserOperation(userOp);
    }

    // Test: Uniswap V2 swap transaction using amount that exceeds the
    // available unlocked balance fails (single)
    function test_transactingLockedTokens_complex_revertIf_notEnoughUnlockedBalance_singleExecute()
        public
    {
        // Set up the test environment
        _testSetup();
        TestWETH weth = new TestWETH();
        TestUniswapV2 uniswapV2 = new TestUniswapV2(weth);
        uni.mint(address(uniswapV2), 10e18);
        dai.approve(address(uniswapV2), 2e18);
        // Enable session key
        _enableDefaultSessionKey();
        // Mint extra tokens to wallet
        dai.mint(address(mew), 1e18);
        // Set up calldata trying to swap 1 DAI more than unlocked balance
        address[] memory paths = new address[](2);
        paths[0] = address(dai);
        paths[1] = address(uni);
        bytes memory swapData = abi.encodeWithSelector(
            TestUniswapV2.swapExactTokensForTokens.selector,
            2e18,
            2e18,
            paths,
            address(mew),
            block.timestamp + 1000
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(uniswapV2), 0, swapData)
            )
        );
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                address(ecdsaValidator),
                owner1Key
            );
        // Expect the HookMultiPlexer.SubHookPostCheckError error to be emitted
        // wrapped in UserOperationRevertReason event
        vm.expectEmit(false, false, false, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOp.nonce,
            abi.encodeWithSelector(
                HMPL.SubHookPostCheckError.selector,
                address(credibleAccountModule)
            )
        );
        // Attempt to execute the user operation
        _executeUserOperation(userOp);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL TESTING
    //////////////////////////////////////////////////////////////*/

    // Test: Should return correct digested ERC20.transferFrom claim
    function test_exposed_digestClaim() public {
        // Set up the test environment
        _testSetup();
        bytes memory data = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            amounts[0]
        );
        (bytes4 selector, address from, address to, uint256 amount) = harness
            .exposed_digestClaimTx(data);
        assertEq(selector, IERC20.transferFrom.selector);
        assertEq(from, address(mew));
        assertEq(to, address(alice));
        assertEq(amount, amounts[0]);
    }

    // Test: Should return blank information for non-ERC20.transfer claims
    function test_exposed_digestClaim_nonTransferFrom() public {
        // Set up the test environment
        _testSetup();
        bytes memory data = _createTokenTransferExecution(
            address(alice),
            amounts[0]
        );
        (bytes4 selector, address from, address to, uint256 amount) = harness
            .exposed_digestClaimTx(data);
        assertEq(selector, bytes4(0));
        assertEq(from, address(0));
        assertEq(to, address(0));
        assertEq(amount, 0);
    }

    // Test: Should return correct signature digest
    function test_exposed_digestSignature() public {
        // Set up the test environment and enable a session key
        _testSetup();
        // Lock some tokens
        bytes memory sessionData = _getDefaultSessionData();
        harness.enableSessionKey(sessionData);
        // Prepare user operation data
        bytes memory data = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            amounts[0]
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(usdc), uint256(0), data)
            )
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(credibleAccountModule),
            sessionKeyPrivateKey
        );
        (bytes memory signature, bytes memory proof) = harness
            .exposed_digestSignature(userOp.signature);
        // get expected signature
        (, , uint8 v, bytes32 r, bytes32 s) = _createUserOpWithSignature(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        bytes memory expectedSignature = abi.encodePacked(r, s, v);
        assertEq(signature, expectedSignature, "signature should match");
        assertEq(proof.length, DUMMY_PROOF.length, "merkleProof should match");
        for (uint256 i; i < proof.length; ++i) {
            assertEq(proof[i], DUMMY_PROOF[i], "merkleProof should match");
        }
    }

    // Test: Retrieving locked balances
    function test_exposed_retrieveLockedBalance() public {
        // Set up the test environment
        _testSetup();
        // Lock some tokens
        bytes memory sessionData = _getDefaultSessionData();
        harness.enableSessionKey(sessionData);
        // Lock same tokens again uder different session key
        TokenData[] memory tokenAmounts = new TokenData[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            tokenAmounts[i] = TokenData(tokens[i], 1 wei);
        }
        bytes memory moreSessionData = abi.encode(
            dummySessionKey,
            validAfter,
            validUntil,
            tokenAmounts
        );
        harness.enableSessionKey(moreSessionData);
        // Verify both session keys enabled successfully
        assertEq(
            harness.getSessionKeysByWallet().length,
            2,
            "Two sessions should be enabled successfully"
        );
        // Retrieve the locked balances
        uint256 usdcLocked = harness.exposed_retrieveLockedBalance(
            address(mew),
            address(usdc)
        );
        uint256 daiLocked = harness.exposed_retrieveLockedBalance(
            address(mew),
            address(dai)
        );
        uint256 uniLocked = harness.exposed_retrieveLockedBalance(
            address(mew),
            address(uni)
        );
        // Verify the locked balances
        assertEq(
            usdcLocked,
            amounts[0] + 1 wei,
            "USDC locked balance should match"
        );
        assertEq(
            daiLocked,
            amounts[1] + 1 wei,
            "DAI locked balance should match"
        );
        assertEq(
            uniLocked,
            amounts[2] + 1 wei,
            "UNI locked balance should match"
        );
    }

    // Test: Encoding state of all locked tokens for a wallet
    function test_exposed_cumulativeLockedForWallet() public {
        // Set up the test environment
        _testSetup();
        // Lock some tokens
        bytes memory sessionData = _getDefaultSessionData();
        harness.enableSessionKey(sessionData);
        assertEq(
            harness.getSessionKeysByWallet()[0],
            sessionKey,
            "Tokens should be locked successfully"
        );
        // Call the exposed function
        TokenData[] memory initialBalances = harness
            .exposed_cumulativeLockedForWallet(address(mew));
        // Verify the encoded state
        assertEq(initialBalances.length, 3, "Should have 3 locked tokens");
        assertEq(
            initialBalances[0].token,
            address(usdc),
            "USDC should be first token"
        );
        assertEq(
            initialBalances[0].amount,
            amounts[0],
            "Balance of USDC should be 100 USDC"
        );
        assertEq(
            initialBalances[1].token,
            address(dai),
            "DAI should be first token"
        );
        assertEq(
            initialBalances[1].amount,
            amounts[1],
            "Balance of DAI should be 200 DAI"
        );
        assertEq(
            initialBalances[2].token,
            address(uni),
            "UNI should be second token"
        );
        assertEq(
            initialBalances[2].amount,
            amounts[2],
            "Balance of UNI should be 300 UNI"
        );
    }
}
