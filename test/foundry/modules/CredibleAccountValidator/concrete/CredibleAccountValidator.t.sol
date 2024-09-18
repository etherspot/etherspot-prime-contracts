// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../../../src/modular-etherspot-wallet/modules/validators/CredibleAccountValidator.sol";
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
        _enableSessionKeyAndValidate(mew, IERC20.transfer.selector);
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

    // Test: Verify that a session key can be enabled
    function test_enableSessionKey() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(mew, IERC20.transfer.selector);
    }

    // Test: Verify that a session key can be disabled
    function test_disableSessionKey() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (address sessionKey, ) = _enableSessionKeyAndValidate(
            mew,
            IERC20.transfer.selector
        );
        // Disable the session key
        _disableSessionKeyAndValidate(mew, sessionKey);
    }

    // Test: Get current SessionKeyStatus
    function test_getSessionKeyStatus() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            address sessionKey,
            ICredibleAccountValidator.SessionData memory sessionData
        ) = _enableSessionKeyAndValidate(mew, IERC20.transfer.selector);
        assertEq(
            uint256(sessionData.status),
            uint256(ICredibleAccountValidator.SessionKeyStatus.Live)
        );
    }

    // Test: Verify that session key parameters can be validated
    function test_validateSessionKeyParams() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (address sessionKey, ) = _enableSessionKeyAndValidate(
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
    function test_CA_validateUserOp() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICredibleAccountValidator.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(mew, IERC20.transferFrom.selector);
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
        _enableSessionKeyAndValidate(mew, IERC20.transfer.selector);
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
        _enableSessionKeyAndValidate(mew, IERC20.transferFrom.selector);
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

    function test_validateUserOp_setsSessionStatusAsClaimedIfSuccessful()
        public
    {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICredibleAccountValidator.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(mew, IERC20.transfer.selector);
        // Prepare user operation data
        bytes memory data = _createTokenTransferExecution(solver, amounts[1]);
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(tokens[1], uint256(0), data)
            )
        );
        // Create the UserOperation
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        // Execute the UserOperation
        _executeUserOperation(userOp);
        // Validate session status has been updated to claimed
        assertEq(
            uint256(credibleAccountValidator.getSessionKeyStatus(sessionKey)),
            uint256(ICredibleAccountValidator.SessionKeyStatus.Claimed)
        );
    }

    // TODO: test validateUserOp sets session status as expired if encoded sig time > validUntil
    // NOTE: need to rethink this logic as if failed op will revert state changes and leave as live
    function test_validateUserOp_setsSessionStatusAsExpired_ifSessionValidityExpired()
        public
    {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICredibleAccountValidator.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(mew, IERC20.transfer.selector);
        // Prepare user operation data
        bytes memory data = _createTokenTransferExecution(solver, amounts[1]);
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(tokens[1], uint256(0), data)
            )
        );
        // Create the UserOperation
        (
            PackedUserOperation memory userOp,
            ,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = _createUserOpWithSignature(
                address(mew),
                userOpCalldata,
                sessionKeyPrivateKey
            );
        (
            bytes32 merkleRoot,
            bytes32[] memory merkleProof
        ) = getDummyMerkleRootAndProof();
        // Set the signature with an expired timestamp
        userOp.signature = abi.encodePacked(
            r,
            s,
            v,
            uint48(block.timestamp + 2 days),
            merkleRoot,
            merkleProof
        );
        // Expect the operation to revert due to signature error
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the UserOperation
        _executeUserOperation(userOp);
        // Validate session status has been updated to expired
        assertEq(
            uint256(credibleAccountValidator.getSessionKeyStatus(sessionKey)),
            uint256(ICredibleAccountValidator.SessionKeyStatus.Expired)
        );
    }

    // Test: validateUserOp reverts if session status is not live
    function test_validateUserOp_revertsIf_sessionStatusIsNotLive() public {
        // Set up the test environment and enable a session key
        _testSetup();
        // Get default session data
        bytes memory sessionData = _getDefaultSessionData(
            IERC20.transfer.selector
        );
        // Enable session key on harness
        credibleAccountValidatorHarness.enableSessionKey(sessionData);
        // Set session status to expired
        credibleAccountValidatorHarness.exposed_setSessionKeyStatus(
            sessionKey,
            ICredibleAccountValidator.SessionKeyStatus.Expired
        );
        // Validate session status has been updated to expired
        assertEq(
            uint256(
                credibleAccountValidatorHarness.getSessionKeyStatus(sessionKey)
            ),
            uint256(ICredibleAccountValidator.SessionKeyStatus.Expired)
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
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(
            address(mew),
            address(credibleAccountValidatorHarness)
        );
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivateKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        (
            bytes32 merkleRoot,
            bytes32[] memory merkleProof
        ) = getDummyMerkleRootAndProof();
        userOp.signature = abi.encodePacked(
            r,
            s,
            v,
            uint48(block.timestamp),
            merkleRoot,
            merkleProof
        );
        // Expect the operation to revert due to signature error (expired session)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the UserOperation
        _executeUserOperation(userOp);
    }

    // Test: Verify end-to-end user operation handling
    function test_e2e_handleUserOp() public {
        // Set up the test environment and enable a session key
        _testSetup();
        _enableSessionKeyAndValidate(mew, IERC20.transferFrom.selector);
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

    function test_exposed_validateSingleCall() public {
        // Set up the test environment and enable a session key
        _testSetup();
        (
            ,
            ICredibleAccountValidator.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(mew, IERC20.transferFrom.selector);
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

        bool isValid = credibleAccountValidatorHarness
            .exposed_validateSingleCall(
                userOpCalldata,
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

        isValid = credibleAccountValidatorHarness.exposed_validateSingleCall(
            userOpCalldata,
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
            ICredibleAccountValidator.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(mew, IERC20.transferFrom.selector);

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

        bool isValid = credibleAccountValidatorHarness
            .exposed_validateBatchCall(
                userOpCalldata,
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

        isValid = credibleAccountValidatorHarness.exposed_validateBatchCall(
            userOpCalldata,
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
            ICredibleAccountValidator.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(mew, IERC20.transferFrom.selector);

        address[] memory tokens_data = new address[](3);
        tokens_data[0] = address(usdc);
        tokens_data[1] = address(dai);
        tokens_data[2] = address(uni);

        bool isValid = credibleAccountValidatorHarness
            .exposed_validateTokenData(
                tokens_data,
                IERC20.transferFrom.selector,
                address(mew),
                address(mew),
                amounts[0],
                address(usdc)
            );

        assertTrue(isValid, "validate token-data should be valid");

        isValid = credibleAccountValidatorHarness.exposed_validateTokenData(
            tokens_data,
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
            ICredibleAccountValidator.SessionData memory sessionDataStruct
        ) = _enableSessionKeyAndValidate(mew, IERC20.transferFrom.selector);
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
            uint48 currentTimestamp,
            bytes32 merkleRoot,
            bytes32[] memory merkleProof
        ) = credibleAccountValidatorHarness.exposed_digestSignature(
                userOp.signature
            );

        // get expected signature
        (, , uint8 v, bytes32 r, bytes32 s) = _createUserOpWithSignature(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        bytes memory expectedSignature = abi.encodePacked(r, s, v);

        assertEq(signature, expectedSignature, "signature should match");

        (
            bytes32 expectedMerkleRoot,
            bytes32[] memory expectedMerkleProof
        ) = getDummyMerkleRootAndProof();

        assertEq(
            merkleProof.length,
            expectedMerkleProof.length,
            "merkleProof should match"
        );

        for (uint i = 0; i < merkleProof.length; i++) {
            assertEq(
                merkleProof[i],
                expectedMerkleProof[i],
                "merkleProof should match"
            );
        }

        assertEq(merkleRoot, expectedMerkleRoot, "merkleRoot should match");
    }

    function test_exposed_setSessionKeyStatus() public {
        // Set up the test environment and enable a session key
        _testSetup();
        // Get default session data
        bytes memory sessionData = _getDefaultSessionData(
            IERC20.transferFrom.selector
        );
        // Enable session key on harness
        credibleAccountValidatorHarness.enableSessionKey(sessionData);
        // Verify that session key is initialized with live status
        assertEq(
            uint256(
                credibleAccountValidatorHarness.getSessionKeyStatus(sessionKey)
            ),
            uint256(ICredibleAccountValidator.SessionKeyStatus.Live),
            "Session key status should be live"
        );
        // Change the session status to expired
        credibleAccountValidatorHarness.exposed_setSessionKeyStatus(
            sessionKey,
            ICredibleAccountValidator.SessionKeyStatus.Expired
        );
        // Verify that session status is now expired
        assertEq(
            uint256(
                credibleAccountValidatorHarness.getSessionKeyStatus(sessionKey)
            ),
            uint256(ICredibleAccountValidator.SessionKeyStatus.Expired),
            "Session key status should be expired"
        );
    }
}
