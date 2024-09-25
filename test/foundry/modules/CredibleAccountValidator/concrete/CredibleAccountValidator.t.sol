// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../../../src/modular-etherspot-wallet/modules/validators/CredibleAccountValidator.sol";
import {ICredibleAccountValidator as ICAV} from "../../../../../src/modular-etherspot-wallet/interfaces/ICredibleAccountValidator.sol";
import "../../../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {CredibleAccountValidatorTestUtils as CAV_TestUtils} from "../utils/CredibleAccountValidatorTestUtils.sol";
import "../../../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import "../../../../../src/modular-etherspot-wallet/test/TestUSDC.sol";
import "../../../../../account-abstraction/contracts/core/Helpers.sol";
import {PackedUserOperation} from "../../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {VALIDATION_FAILED} from "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../../TestAdvancedUtils.t.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";

using ERC4337Utils for IEntryPoint;

contract CredibleAccountValidator_Concrete_Test is CAV_TestUtils {
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CredibleAccountValidator_ModuleInstalled(address wallet);
    event CredibleAccountValidator_ModuleUninstalled(address wallet);
    event CredibleAccountValidator_SessionKeyEnabled(
        address sessionKey,
        address wallet
    );
    event CredibleAccountValidator_SessionKeyDisabled(
        address sessionKey,
        address wallet
    );
    event CredibleAccountValidator_SessionKeyPaused(
        address sessionKey,
        address wallet
    );
    event CredibleAccountValidator_SessionKeyUnpaused(
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
                                TESTS
    //////////////////////////////////////////////////////////////*/

    // Test: Verify that the CredibleAccountValidator module can be installed
    function test_installModule() public {
        // Set up the test environment with CredibleAccountValidator
        _testSetup();
        // Verify that the module is installed
        assertTrue(
            mew.isModuleInstalled(
                1,
                address(credibleAccountValidator),
                "CredibleAccountValidator module should be installed"
            )
        );
    }

    // Test: Verify that the CredibleAccountValidator module can be uninstalled
    function test_uninstallModule() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transfer.selector
        );
        assertEq(
            credibleAccountValidator.getAssociatedSessionKeys().length,
            1,
            "There should be one session key"
        );

        // solver to claim the locked tokens before uninstalling the module

        // Prepare Executions
        Execution[] memory executions = new Execution[](3);
        bytes memory dataUSDC = _createTokenTransferExecution(
            address(solver),
            amounts[0]
        );
        bytes memory dataDAI = _createTokenTransferExecution(
            address(solver),
            amounts[1]
        );
        bytes memory dataUNI = _createTokenTransferExecution(
            address(solver),
            amounts[2]
        );
        executions[0] = Execution({
            target: address(usdc),
            value: 0,
            callData: dataUSDC
        });
        executions[1] = Execution({
            target: address(dai),
            value: 0,
            callData: dataDAI
        });
        executions[2] = Execution({
            target: address(uni),
            value: 0,
            callData: dataUNI
        });
        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );
        (, PackedUserOperation memory claimUserOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        // Execute the user operation (solver to claim all the locked tokens)
        _executeUserOperation(claimUserOp);

        // Get the previous validator for linked list management
        address prevValidator = _getPrevValidator(
            address(credibleAccountValidator)
        );
        // Prepare uninstallation call
        Execution[] memory batchCall2 = new Execution[](1);
        batchCall2[0].target = address(mew);
        batchCall2[0].value = 0;
        batchCall2[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.uninstallModule.selector,
            uint256(1),
            address(credibleAccountValidator),
            abi.encode(prevValidator, hex"")
        );
        // Expect the uninstallation event to be emitted
        vm.expectEmit(false, false, false, true);
        emit CredibleAccountValidator_ModuleUninstalled(address(mew));
        // Execute the uninstallation
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall2);
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
                address(credibleAccountValidator),
                "CredibleAccountValidator module should not be installed"
            )
        );
        assertFalse(
            credibleAccountValidator.isInitialized(address(mew)),
            "CredibleAccountValidator module should not be initialized"
        );
        assertEq(
            credibleAccountValidator.getAssociatedSessionKeys().length,
            0,
            "There should be no session keys"
        );
    }

        // Test: Verify that the CredibleAccountValidator module can be uninstalled
    function test_fail_uninstallModule_withActiveUnclaimedSessions() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transfer.selector
        );
        assertEq(
            credibleAccountValidator.getAssociatedSessionKeys().length,
            1,
            "There should be one session key"
        );

        // Get the previous validator for linked list management
        address prevValidator = _getPrevValidator(
            address(credibleAccountValidator)
        );
        // Prepare uninstallation call
        Execution[] memory batchCall2 = new Execution[](1);
        batchCall2[0].target = address(mew);
        batchCall2[0].value = 0;
        batchCall2[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.uninstallModule.selector,
            uint256(1),
            address(credibleAccountValidator),
            abi.encode(prevValidator, hex"")
        );
        
        vm.expectRevert(
            abi.encodeWithSelector(
                CredibleAccountValidator.CredibleAccountValidator_LockedTokensNotClaimed.selector,
                sessionKey
            )
        );

        // Execute the uninstallation
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall2);

    }


    // Test: Verify that a session key can be enabled
    function test_enableSessionKey() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transfer.selector
        );
    }

    // Test: Verify that a session key can be disabled
    function test_successfulDisableSessionKey() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (address sessionKey, ) = _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transfer.selector
        );

        // Prepare Executions
        Execution[] memory executions = new Execution[](3);
        bytes memory dataUSDC = _createTokenTransferExecution(
            address(solver),
            amounts[0]
        );
        bytes memory dataDAI = _createTokenTransferExecution(
            address(solver),
            amounts[1]
        );
        bytes memory dataUNI = _createTokenTransferExecution(
            address(solver),
            amounts[2]
        );
        executions[0] = Execution({
            target: address(usdc),
            value: 0,
            callData: dataUSDC
        });
        executions[1] = Execution({
            target: address(dai),
            value: 0,
            callData: dataDAI
        });
        executions[2] = Execution({
            target: address(uni),
            value: 0,
            callData: dataUNI
        });
        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        // Execute the user operation (solver to claim all the locked tokens)
        _executeUserOperation(userOp);

        vm.expectEmit(true, true, true, true);
        emit ICAV.CredibleAccountValidator_SessionKeyDisabled(
            sessionKey,
            address(mew)
        );

        vm.warp(block.timestamp + 1 days);

        // Disable the session key
        credibleAccountValidator.disableSessionKey(sessionKey);
        ICAV.SessionData memory sessionData = credibleAccountValidator
            .getSessionKeyData(sessionKey);
        assertEq(sessionData.validUntil, 0);
        assertEq(sessionData.validAfter, 0);
        assertEq(sessionData.selector, bytes4(0));
        assertEq(sessionData.lockedTokens.length, 0);
    }

    function test_Successful_DisableSessionKey_With_PartialClaim() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (address sessionKey, ) = _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transfer.selector
        );

        // Prepare Executions
        Execution[] memory executions = new Execution[](2);
        bytes memory dataUSDC = _createTokenTransferExecution(
            address(solver),
            amounts[0]
        );
        bytes memory dataDAI = _createTokenTransferExecution(
            address(solver),
            amounts[1]
        );

        executions[0] = Execution({
            target: address(usdc),
            value: 0,
            callData: dataUSDC
        });
        executions[1] = Execution({
            target: address(dai),
            value: 0,
            callData: dataDAI
        });
        
        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        // Execute the user operation (Solve to partial claim - claims only 2 out of 3 locked tokens)
        _executeUserOperation(userOp);

        vm.warp(block.timestamp + 1 days);

        // Disable the session key
        credibleAccountValidator.disableSessionKey(sessionKey);
    }

    function test_fail_DisableSessionKey_With_PartialClaim() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (address sessionKey, ) = _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transfer.selector
        );

        // Prepare Executions
        Execution[] memory executions = new Execution[](2);
        bytes memory dataUSDC = _createTokenTransferExecution(
            address(solver),
            amounts[0]
        );
        bytes memory dataDAI = _createTokenTransferExecution(
            address(solver),
            amounts[1]
        );

        executions[0] = Execution({
            target: address(usdc),
            value: 0,
            callData: dataUSDC
        });
        executions[1] = Execution({
            target: address(dai),
            value: 0,
            callData: dataDAI
        });
        
        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        // Execute the user operation (Solve to partial claim - claims only 2 out of 3 locked tokens)
        _executeUserOperation(userOp);

        vm.expectRevert(
            abi.encodeWithSelector(
                CredibleAccountValidator.CredibleAccountValidator_LockedTokensNotClaimed.selector,
                sessionKey
            )
        );

        // Disable the session key
        credibleAccountValidator.disableSessionKey(sessionKey);
    }

    function test_fail_DisableNonExistingSessionKey() public {
        // Set up the test environment and enable a session key
        _testSetup();

        vm.expectRevert(
            abi.encodeWithSelector(
                CredibleAccountValidator.CredibleAccountValidator_SessionKeyDoesNotExist.selector,
                dummySessionKey
            )
        );

        // Disable the session key
        credibleAccountValidator.disableSessionKey(dummySessionKey);
    }

    // Test: Verify that session key parameters can be validated
    function test_validateSessionKeyParams() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (address sessionKey, ) = _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transferFrom.selector
        );
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
            sessionKeyPrivateKey
        );
        // Validate session key parameters
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        assertTrue(
            credibleAccountValidator.validateSessionKeyParams(
                sessionKey,
                userOp
            ),
            "Session key parameters should be valid"
        );
    }

    // Test: Verify that a user operation can be validated
    function test_validateUserOp() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICAV.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(
                credibleAccountValidator,
                mew,
                IERC20.transferFrom.selector
            );
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

        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                sessionKeyPrivateKey
            );
        // Validate the user operation
        uint256 validationData = credibleAccountValidator.validateUserOp(
            userOp,
            hash
        );
        uint256 expectedValidationData = _packValidationData(
            false,
            sessionDataStruct.validUntil,
            sessionDataStruct.validAfter
        );
        assertEq(
            validationData,
            expectedValidationData,
            "Validation data should match"
        );
    }

    // Test: Verify that validation fails for an invalid function selector
    function test_fail_validateUserOp_invalidFunctionSelector() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transfer.selector
        );
        // Prepare user operation data with invalid selector
        bytes memory data = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            100 * 10 ** 6
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(usdc), uint256(0), data)
            )
        );
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                sessionKeyPrivateKey
            );
        // Validate the user operation (should fail)
        uint256 validationData = credibleAccountValidator.validateUserOp(
            userOp,
            hash
        );
        assertEq(validationData, VALIDATION_FAILED, "Validation should fail");
    }

    // Test: Verify that validation fails when signed by an invalid key
    function test_fail_sessionSignedByInvalidKey() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transferFrom.selector
        );
        // Prepare user operation data signed by an invalid key
        bytes memory data = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            100 * 10 ** 6
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(usdc), uint256(0), data)
            )
        );
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(address(mew), userOpCalldata, owner1Key);
        // Validate the user operation (should fail)
        uint256 validationData = credibleAccountValidator.validateUserOp(
            userOp,
            hash
        );
        assertEq(validationData, VALIDATION_FAILED, "Validation should fail");
    }

    // Test: Verify end-to-end user operation handling
    function test_e2e_handleUserOp() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transferFrom.selector
        );
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
            sessionKeyPrivateKey
        );
        // Execute the user operation
        _executeUserOperation(userOp);
        // Verify the token transfer
        assertEq(
            usdc.balanceOf(address(alice)),
            amounts[0],
            "Alice's balance should match the transferred amount"
        );
    }

    function test_successfulSolverClaimIsClaimed() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transfer.selector
        );
        // Prepare Executions
        Execution[] memory executions = new Execution[](3);
        bytes memory dataUSDC = _createTokenTransferExecution(
            address(solver),
            amounts[0]
        );
        bytes memory dataDAI = _createTokenTransferExecution(
            address(solver),
            amounts[1]
        );
        bytes memory dataUNI = _createTokenTransferExecution(
            address(solver),
            amounts[2]
        );
        executions[0] = Execution({
            target: address(usdc),
            value: 0,
            callData: dataUSDC
        });
        executions[1] = Execution({
            target: address(dai),
            value: 0,
            callData: dataDAI
        });
        executions[2] = Execution({
            target: address(uni),
            value: 0,
            callData: dataUNI
        });
        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        // Execute the user operation
        _executeUserOperation(userOp);
        // Verify the token transfer
        assertEq(
            usdc.balanceOf(address(solver)),
            amounts[0],
            "Solver's USDC balance should match the transferred amount"
        );
        assertEq(
            dai.balanceOf(address(solver)),
            amounts[1],
            "Solver's DAI balance should match the transferred amount"
        );
        assertEq(
            uni.balanceOf(address(solver)),
            amounts[2],
            "Solver's UNI balance should match the transferred amount"
        );
        assertTrue(credibleAccountValidator.isSessionClaimed(sessionKey));
    }

    function test_successfulSolverPartialClaimIsNotClaimed() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transfer.selector
        );
        // Prepare Executions
        Execution[] memory executions = new Execution[](3);
        bytes memory dataUSDC = _createTokenTransferExecution(
            address(solver),
            amounts[0]
        );
        bytes memory dataDAI = _createTokenTransferExecution(
            address(solver),
            amounts[1]
        );
        bytes memory dataUNI = _createTokenTransferExecution(
            address(solver),
            amounts[2] - 1
        );
        executions[0] = Execution({
            target: address(usdc),
            value: 0,
            callData: dataUSDC
        });
        executions[1] = Execution({
            target: address(dai),
            value: 0,
            callData: dataDAI
        });
        executions[2] = Execution({
            target: address(uni),
            value: 0,
            callData: dataUNI
        });
        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        // Execute the user operation
        _executeUserOperation(userOp);
        // Verify the token transfer
        assertEq(
            usdc.balanceOf(address(solver)),
            amounts[0],
            "Solver's USDC balance should match the transferred amount"
        );
        assertEq(
            dai.balanceOf(address(solver)),
            amounts[1],
            "Solver's DAI balance should match the transferred amount"
        );
        assertEq(
            uni.balanceOf(address(solver)),
            amounts[2] - 1,
            "Solver's UNI balance should match the transferred amount"
        );
        assertFalse(credibleAccountValidator.isSessionClaimed(sessionKey));
        (uint256 usdcLocked, uint256 usdcClaimed) = credibleAccountValidator
            .getTokenAmounts(sessionKey, tokens[0]);
        (uint256 daiLocked, uint256 daiClaimed) = credibleAccountValidator
            .getTokenAmounts(sessionKey, tokens[1]);
        (uint256 uniLocked, uint256 uniClaimed) = credibleAccountValidator
            .getTokenAmounts(sessionKey, tokens[2]);
        assertEq(usdcLocked, amounts[0]);
        assertEq(usdcClaimed, amounts[0]);
        assertEq(daiLocked, amounts[1]);
        assertEq(daiClaimed, amounts[1]);
        assertEq(uniLocked, amounts[2]);
        assertEq(uniClaimed, amounts[2] - 1);
    }

    function test_singleExecute_failedSolverClaimExpiredSession() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transfer.selector
        );
        // Prepare user operation data
        bytes memory data = _createTokenTransferExecution(solver, amounts[1]);
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(tokens[1], uint256(0), data)
            )
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        // warp two days to make validUntil < current timestamp
        vm.warp(172800);
        // Expect the operation to revert due to signature error (expired session)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA22 expired or not due"
            )
        );
        // Execute the user operation
        _executeUserOperation(userOp);
    }

    function test_exposed_validateSingleCall() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICAV.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(
                harness,
                mew,
                IERC20.transferFrom.selector
            );
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

        bool isValid = harness.exposed_validateSingleCall(
            userOpCalldata,
            sessionKey,
            sessionDataStruct,
            address(mew)
        );

        assertTrue(isValid, "validate single-call should be valid");

        userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(aave), uint256(0), data)
            )
        );

        isValid = harness.exposed_validateSingleCall(
            userOpCalldata,
            sessionKey,
            sessionDataStruct,
            address(mew)
        );

        assertFalse(isValid, "validate single-call should be in-valid");
    }

    function test_exposed_validateBatchCall() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICAV.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(
                harness,
                mew,
                IERC20.transferFrom.selector
            );

        Execution[] memory executions = new Execution[](3);

        bytes memory data_usdc = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            amounts[0]
        );

        executions[0] = Execution({
            target: address(usdc),
            value: 0,
            callData: data_usdc
        });

        bytes memory data_dai = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            amounts[1]
        );

        executions[1] = Execution({
            target: address(dai),
            value: 0,
            callData: data_dai
        });

        bytes memory data_uni = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            amounts[2]
        );

        executions[2] = Execution({
            target: address(uni),
            value: 0,
            callData: data_uni
        });

        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );

        bool isValid = harness.exposed_validateBatchCall(
            userOpCalldata,
            sessionKey,
            sessionDataStruct,
            address(mew)
        );

        assertTrue(isValid, "validate batch-call should be valid");

        bytes memory data_aave = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            amounts[2]
        );

        executions[2] = Execution({
            target: address(aave),
            value: 0,
            callData: data_aave
        });

        // Encode the call into the calldata for the userOp
        userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );

        isValid = harness.exposed_validateBatchCall(
            userOpCalldata,
            sessionKey,
            sessionDataStruct,
            address(mew)
        );

        assertFalse(isValid, "validate batch-call should be in-valid");
    }

    function test_exposed_validateTokenData() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICAV.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(
                harness,
                mew,
                IERC20.transferFrom.selector
            );

        ICAV.LockedToken[] memory lockedTokens = new ICAV.LockedToken[](3);
        lockedTokens[0] = ICAV.LockedToken({
            token: tokens[0],
            lockedAmount: amounts[0],
            claimedAmount: 0
        });
        lockedTokens[1] = ICAV.LockedToken({
            token: tokens[1],
            lockedAmount: amounts[1],
            claimedAmount: 0
        });
        lockedTokens[2] = ICAV.LockedToken({
            token: tokens[2],
            lockedAmount: amounts[2],
            claimedAmount: 0
        });

        bool isValid = harness.exposed_validateTokenData(
            sessionKey,
            lockedTokens,
            IERC20.transferFrom.selector,
            address(mew),
            address(mew),
            amounts[0],
            tokens[0]
        );

        assertTrue(isValid, "validate token-data should be valid");

        isValid = harness.exposed_validateTokenData(
            sessionKey,
            lockedTokens,
            IERC20.transferFrom.selector,
            address(mew),
            address(mew),
            amounts[0],
            address(aave)
        );

        assertFalse(isValid, "validate token-data should be in-valid");
    }

    function test_exposedSignatureDigest() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICAV.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(
                harness,
                mew,
                IERC20.transferFrom.selector
            );
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

        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                sessionKeyPrivateKey
            );

        (
            bytes memory signature,
            bytes memory proof
        ) = harness.exposed_digestSignature(userOp.signature);

        // get expected signature
        (, , uint8 v, bytes32 r, bytes32 s) = _createUserOpWithSignature(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        bytes memory expectedSignature = abi.encodePacked(r, s, v);

        assertEq(signature, expectedSignature, "signature should match");

        assertEq(
            proof.length,
            DUMMY_PROOF.length,
            "merkleProof should match"
        );

        for (uint i = 0; i < proof.length; ++i) {
            assertEq(
                proof[i],
                DUMMY_PROOF[i],
                "merkleProof should match"
            );
        }
    }

    function test_validateSingleCall_fail_if_unlockAmount_exceedsLockedAmount() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICAV.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(
                harness,
                mew,
                IERC20.transferFrom.selector
            );
        // Prepare user operation data
        bytes memory data = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            amounts[0]+1
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(usdc), uint256(0), data)
            )
        );

        bool isValid = harness.exposed_validateSingleCall(
            userOpCalldata,
            sessionKey,
            sessionDataStruct,
            address(mew)
        );

        assertFalse(isValid, "validate single-call should be valid");
    }

    function test_validate_fail_unlock_makes_ClaimedAmount_exceed_LockedAmount() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICAV.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(
            credibleAccountValidator,
            mew,
            IERC20.transferFrom.selector
        );

        uint256 lockedAmount = amounts[0];
        uint256 unlockAmount = amounts[0] / 100;
        uint256 remainingAmount = lockedAmount - unlockAmount;

        // Prepare user operation data
        bytes memory data = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            unlockAmount
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
            sessionKeyPrivateKey
        );
        // Execute the user operation
        _executeUserOperation(userOp);
        // Verify the token transfer
        assertEq(
            usdc.balanceOf(address(alice)),
            unlockAmount,
            "Alice's balance should match the transferred amount"
        );

         // Prepare user operation data
        data = _createTokenTransferFromExecution(
            address(mew),
            address(alice),
            remainingAmount * 10
        );
        userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(usdc), uint256(0), data)
            )
        );

        bool isValid = harness.exposed_validateSingleCall(
            userOpCalldata,
            sessionKey,
            sessionDataStruct,
            address(mew)
        );

        assertFalse(isValid, "validate single-call should be valid");
    }
}
