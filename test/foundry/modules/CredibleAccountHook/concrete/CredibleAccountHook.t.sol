// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ICredibleAccountHook as ICAH} from "../../../../../src/modular-etherspot-wallet/interfaces/ICredibleAccountHook.sol";
import {CredibleAccountHook} from "../../../../../src/modular-etherspot-wallet/modules/hooks/CredibleAccountHook.sol";
import {CredibleAccountHookTestUtils} from "../utils/CredibleAccountHookTestUtils.sol";
import {TestCounter} from "../../../../../src/modular-etherspot-wallet/test/TestCounter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ExecutionLib.sol";
import "../../../TestAdvancedUtils.t.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";

using ERC4337Utils for IEntryPoint;

contract CredibleAccountHook_Concrete_Test is CredibleAccountHookTestUtils {
    using ModeLib for ModeCode;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CredibleAccountHook_ModuleInstalled(address indexed wallet);
    event CredibleAccountHook_ModuleUninstalled(address indexed wallet);
    event CredibleAccountHook_TokenLocked(
        address indexed wallet,
        address indexed token,
        uint256 indexed amount
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

    // Test installation of the CredibleAccountHook module
    function test_installModule() public {
        // Initialize the Modular Etherspot Wallet
        mew = setupMEW();
        vm.startPrank(owner1);
        // Prepare execution data for installing the CredibleAccountHook module
        bytes memory callData = abi.encodeWithSelector(
            IERC7579Account.installModule.selector,
            uint256(4),
            address(caHook),
            hex""
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            callData,
            address(ecdsaValidator),
            owner1Key
        );
        // Expect the CredibleAccountHook_ModuleInstalled event to be emitted
        vm.expectEmit(true, false, false, false);
        emit CredibleAccountHook_ModuleInstalled(address(mew));
        // Execute the module installation
        _executeUserOperation(userOp);
        // Verify that the CredibleAccountHook module is installed
        assertTrue(
            mew.isModuleInstalled(4, address(caHook), ""),
            "CredibleAccountHook module should be installed"
        );
    }

    // Test installing another module while CredibleAccountHook is already installed
    function test_installModule_whileHookIsActive() public {
        // Set up the test environment with CredibleAccountHook already installed
        _testSetup();
        // Create a new validator module to install
        MockValidator newValidator = new MockValidator();
        // Install the new validator module
        defaultExecutor.executeViaAccount(
            IERC7579Account(mew),
            address(mew),
            0,
            abi.encodeWithSelector(
                IERC7579Account.installModule.selector,
                uint256(1),
                address(newValidator),
                ""
            )
        );
        // Verify that the new validator module is installed
        assertTrue(
            mew.isModuleInstalled(1, address(newValidator), ""),
            "Validator module should be installed"
        );
    }

    // Test uninstallation of the CredibleAccountHook module
    function test_uninstallModule() public {
        // Set up the test environment with CredibleAccountHook installed
        _testSetup();
        // Verify that the CredibleAccountHook is initially installed
        assertTrue(
            mew.isModuleInstalled(4, address(caHook), ""),
            "CredibleAccountHook module should be installed"
        );
        // Expect the CredibleAccountHook_ModuleUninstalled event to be emitted
        vm.expectEmit(true, false, false, false);
        emit CredibleAccountHook_ModuleUninstalled(address(mew));
        // Uninstall the CredibleAccountHook module
        defaultExecutor.executeViaAccount(
            IERC7579Account(mew),
            address(mew),
            0,
            abi.encodeWithSelector(
                IERC7579Account.uninstallModule.selector,
                uint256(4),
                address(caHook),
                ""
            )
        );
        // Verify that the CredibleAccountHook module is uninstalled
        assertFalse(
            mew.isModuleInstalled(4, address(caHook), ""),
            "CredibleAccountHook module should be uninstalled"
        );
    }

    // Test that uninstalling the CredibleAccountHook module fails when a transaction is in progress
    function test_uninstallModule_revertIf_transactionInProgress() public {
        // Set up the test environment and install a MockValidator
        _testSetup();
        // Set up and execute a user operation to enable a session key
        bytes memory sessionData = _getDefaultSessionData();
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        entrypoint.handleOps(userOps, beneficiary);
        // Verify that a transaction is in progress
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should be in progress"
        );
        // Attempt to uninstall the CredibleAccountHook module while a transaction is in progress
        // Expect the operation to revert with CredibleAccountHook_CantUninstallWhileTransactionInProgress error
        vm.expectRevert(
            abi.encodeWithSelector(
                CredibleAccountHook
                    .CredibleAccountHook_CantUninstallWhileTransactionInProgress
                    .selector,
                address(mew)
            )
        );
        defaultExecutor.executeViaAccount(
            IERC7579Account(mew),
            address(mew),
            0,
            abi.encodeWithSelector(
                IERC7579Account.uninstallModule.selector,
                uint256(4),
                address(caHook),
                ""
            )
        );
    }

    // Test that the CredibleAccountHook is properly initialized for a wallet
    function test_isInitialized() public {
        // Set up the test environment
        _testSetup();
        // Verify that the CredibleAccountHook is initialized for the wallet
        assertTrue(
            caHook.isInitialized(address(mew)),
            "CredibleAccountHook should be initialized"
        );
    }

    // Test that the CredibleAccountHook is recognized as the correct module type
    function test_isModuleType() public {
        // Verify that the CredibleAccountHook is recognized as a hook module (type 4)
        assertTrue(
            caHook.isModuleType(4),
            "CredibleAccountHook should be recognized as a hook module"
        );
        // Verify that the CredibleAccountHook is not recognized as a validator module (type 1)
        assertFalse(
            caHook.isModuleType(1),
            "CredibleAccountHook should not be recognized as a different module"
        );
    }

    // Test locking tokens with a single execution
    function test_lockingTokens_singleExecute() public {
        // Set up the test environment and install a MockValidator
        _testSetup();
        // Set up and execute a user operation to enable a session key
        bytes memory sessionData = _getDefaultSessionData();
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        entrypoint.handleOps(userOps, beneficiary);
        // Verify that tokens are locked and a transaction is in progress
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should be in progress"
        );
        _verifyTokenLocking(address(token1), true);
        _verifyTokenLocking(address(token2), true);
    }

    // Test locking tokens with a batch execution
    function test_lockingTokens_batchExecute() public {
        // Set up the test environment
        _testSetup();
        // Prepare and execute a batch operation to enable a session key
        bytes memory sessionData = _getDefaultSessionData();
        Execution[] memory batchCall = new Execution[](1);
        batchCall[0].target = address(caValidator);
        batchCall[0].value = 0;
        batchCall[0].callData = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            sessionData
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getLockingMode(CALLTYPE_BATCH),
                ExecutionLib.encodeBatch(batchCall)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(ecdsaValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            owner1Key,
            ECDSA.toEthSignedMessageHash(hash)
        );
        userOp.signature = abi.encodePacked(r, s, v);
        _executeUserOperation(userOp);
        // Verify that tokens are locked and a transaction is in progress
        _verifyTokenLocking(address(token1), true);
        _verifyTokenLocking(address(token2), true);
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should be in progress"
        );
    }

    // Test locking more of the same token in a different session key
    function test_lockingTokens_lockingMoreOfSameTokenInDifferentSessionKey()
        public
    {
        // Set up the test environment and install a MockValidator
        _testSetup();
        // Enable a session key and lock tokens
        bytes memory sessionData = _getDefaultSessionData();
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        entrypoint.handleOps(userOps, beneficiary);
        // Verify initial token locking
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should be in progress"
        );
        _verifyTokenLocking(address(token1), true);
        _verifyTokenLocking(address(token2), true);
        // Lock more of the same token with a different session key
        address anotherSessionKey = address(0x535510);
        token1.mint(address(mew), 13 ether);
        token1.approve(address(mew), 13 ether);
        sessionData = abi.encodePacked(
            anotherSessionKey,
            solver,
            selector,
            validAfter,
            validUntil,
            uint256(1),
            [address(token1)],
            uint256(1),
            [13 ether]
        );
        (, userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        entrypoint.handleOps(userOps, beneficiary);
        // Verify updated token locking
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should be in progress"
        );
        _verifyTokenLocking(address(token1), true);
        _verifyTokenLocking(address(token2), true);
        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            14 ether,
            "Token 1 balance should be updated to include cumulative amount"
        );
        assertEq(
            caHook.retrieveLockedBalance(address(token2)),
            2 ether,
            "Token 2 balance should remain unchanged"
        );
    }

    // Test that locking tokens fails when there's not enough unlocked balance
    function test_lockingTokens_revertIf_notEnoughUnlockedBalance() public {
        // Set up the test environment and install a MockValidator
        _testSetup();
        // Enable a session key and lock tokens
        bytes memory sessionData = _getDefaultSessionData();
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        entrypoint.handleOps(userOps, beneficiary);
        // Attempt to transfer more tokens than the unlocked balance
        bytes memory callData = _createTokenTransferExecution(
            address(receiver),
            1 ether
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(token1), 0, callData)
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
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the operation to revert with CredibleAccountHook_InsufficientUnlockedBalance error
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOps[0].nonce,
            abi.encodeWithSelector(
                CredibleAccountHook
                    .CredibleAccountHook_InsufficientUnlockedBalance
                    .selector,
                address(token1)
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    // Test that locking tokens fails when trying to use an already existing session key
    function test_lockingTokens_revertIf_sessionKeyAlreadyUsed() public {
        // Set up the test environment and install a MockValidator
        _testSetup();
        // Enable a session key and lock tokens
        bytes memory sessionData = _getDefaultSessionData();
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        entrypoint.handleOps(userOps, beneficiary);
        // Attempt to use the same session key again
        token1.mint(address(mew), 1 ether);
        token1.approve(address(mew), 1 ether);
        token2.mint(address(mew), 2 ether);
        token2.approve(address(mew), 2 ether);
        (
            bytes32 hash,
            PackedUserOperation[] memory userOps1
        ) = _enableSessionKeyUserOp(
                address(mew),
                _getLockingMode(CALLTYPE_SINGLE),
                sessionData,
                owner1Key
            );
        // Expect the operation to revert with CredibleAccountHook_SessionKeyAlreadyExists error
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOps1[0].nonce,
            abi.encodeWithSelector(
                CredibleAccountHook
                    .CredibleAccountHook_SessionKeyAlreadyExists
                    .selector,
                address(mew),
                sessionKey
            )
        );
        entrypoint.handleOps(userOps1, beneficiary);
    }

    // Test that tokens are not locked when no mode selector is provided
    function test_lockingTokens_revertIf_noModeSelector_shouldNotLockTokens()
        public
    {
        // Set up the test environment
        _testSetup();
        // Prepare session data and calldata for enabling a session key
        bytes memory sessionData = _getDefaultSessionData();
        bytes memory callData = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            sessionData
        );
        // Create a user operation without a mode selector
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(caValidator), 0, callData)
            )
        );
        // Prepare and sign the user operation
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                address(ecdsaValidator),
                owner1Key
            );
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the CredibleAccountHook_CannotEnableSessionKeyWithoutModeSelector error
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOps[0].nonce,
            abi.encodeWithSelector(
                CredibleAccountHook
                    .CredibleAccountHook_CannotEnableSessionKeyWithoutModeSelector
                    .selector
            )
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Verify that no tokens are locked and no transaction is in progress
        assertFalse(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should not be in progress"
        );
        _verifyTokenLocking(address(token1), false);
        _verifyTokenLocking(address(token2), false);
    }

    // Test that tokens are not locked when an invalid mode selector is provided
    function test_lockingTokens_revertIf_invalidModeSelector_shouldNotLockTokens()
        public
    {
        // Set up the test environment
        _testSetup();
        // Prepare session data and calldata for enabling a session key
        bytes memory sessionData = _getDefaultSessionData();
        bytes memory callData = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            sessionData
        );
        // Create an invalid mode selector
        ModeCode mode = ModeCode.wrap(
            bytes32(
                abi.encodePacked(
                    CALLTYPE_SINGLE,
                    ExecType.wrap(0x00),
                    bytes4(0),
                    ModeSelector.wrap(
                        bytes4(keccak256("etherspot.invalidvalidator"))
                    ),
                    bytes22(0)
                )
            )
        );
        // Create a user operation with the invalid mode selector
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (mode, ExecutionLib.encodeSingle(address(caValidator), 0, callData))
        );
        // Prepare and sign the user operation
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                address(ecdsaValidator),
                owner1Key
            );
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the CredibleAccountHook_CannotEnableSessionKeyWithoutModeSelector error
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOps[0].nonce,
            abi.encodeWithSelector(
                CredibleAccountHook
                    .CredibleAccountHook_CannotEnableSessionKeyWithoutModeSelector
                    .selector
            )
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Verify that no tokens are locked and no transaction is in progress
        assertFalse(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should not be in progress"
        );
        _verifyTokenLocking(address(token1), false);
        _verifyTokenLocking(address(token2), false);
    }

    // Test that transferring tokens succeeds when there's enough unlocked balance
    function test_transferTokens_withEnoughUnlockedBalance() public {
        // Set up the test environment and install the mock validator
        _testSetup();
        // Enable a session key and lock tokens
        bytes memory sessionData = _getDefaultSessionData();
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        entrypoint.handleOps(userOps, beneficiary);
        // Attempt to transfer less tokens than the unlocked balance
        token1.mint(address(mew), 2 ether);
        token1.approve(address(mew), 2 ether);
        bytes memory callData = _createTokenTransferExecution(
            address(receiver),
            2 ether
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(token1), 0, callData)
            )
        );
        // Prepare and sign the user operation
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                address(ecdsaValidator),
                owner1Key
            );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Verify transfer and locked balance
        assertEq(
            token1.balanceOf(address(receiver)),
            2 ether,
            "Receiver should have 2 ether (as that is how much was sent)"
        );
        assertEq(
            token1.balanceOf(address(mew)),
            1 ether,
            "Wallet should have 1 ether (3 ether - 2 ether sent to receiver)"
        );
        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            1 ether,
            "Wallet should have 1 ether still locked"
        );
    }

    // Test that transferring tokens fails when there's not enough unlocked balance
    function test_transferTokens_revertIf_notEnoughUnlockedBalance() public {
        // Set up the test environment and install the mock validator
        _testSetup();
        // Enable a session key and lock tokens
        bytes memory sessionData = _getDefaultSessionData();
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        entrypoint.handleOps(userOps, beneficiary);
        // Attempt to transfer more tokens than the unlocked balance
        // 1 ether balance of wallet
        // 1 ether locked amount
        // Test transferring 1 wei which should trigger revert
        bytes memory callData = _createTokenTransferExecution(
            address(receiver),
            1
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(token1), 0, callData)
            )
        );
        // Prepare and sign the user operation
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                address(ecdsaValidator),
                owner1Key
            );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the CredibleAccountHook_InsufficientUnlockedBalance error
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOps[0].nonce,
            abi.encodeWithSelector(
                CredibleAccountHook
                    .CredibleAccountHook_InsufficientUnlockedBalance
                    .selector,
                address(token1)
            )
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
    }

    // Test that other transactions are allowed when tokens are locked that dont effect the locked tokens
    function test_allowOtherTransactionsThatDontEffectLockTokenBalances()
        public
    {
        // Set up the test environment
        _testSetup();
        // Deploy a test counter contract
        TestCounter counter = new TestCounter();
        // Prepare calldata to change the counter value
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.changeCount.selector,
            7579
        );
        // Create a user operation to execute the counter change
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(counter), 0, callData)
            )
        );
        // Prepare and sign the user operation
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(ecdsaValidator),
            owner1Key
        );
        _executeUserOperation(userOp);
        // Verify that the counter value was updated
        assertEq(counter.getCount(), 7579, "Counter value should be updated");
    }

    // Test that unlocking tokens works with a single execute
    function test_unlockingTokens_singleExecute() public {
        // Set up the test environment
        _testSetup();
        // Set up SessionData
        bytes memory sessionData = abi.encodePacked(
            sessionKey,
            solver,
            selector,
            validAfter,
            validUntil,
            uint256(1),
            [address(token1)],
            uint256(1),
            [1 ether]
        );
        // Get enableSessionKey UserOperation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Set up calldata
        bytes memory callData = _createTokenTransferExecution(
            address(solver),
            1 ether
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_SINGLE, sessionKey),
                ExecutionLib.encodeSingle(address(token1), 0, callData)
            )
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(caValidator),
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check tokens are unlocked
        assertFalse(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should not be in progress"
        );
        _verifyTokenLocking(address(token1), false);
        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            0,
            "Locked balance should be 0"
        );
    }

    // Test that partial unlocking tokens works with a single execute
    function test_partialUnlockingTokens_singleExecute() public {
        // Set up the test environment
        _testSetup();
        // Set up SessionData
        bytes memory sessionData = _getDefaultSessionData();
        // Get enableSessionKey UserOperation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Set up calldata
        bytes memory callData = _createTokenTransferExecution(
            address(solver),
            1 ether
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_SINGLE, sessionKey),
                ExecutionLib.encodeSingle(address(token2), 0, callData)
            )
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(caValidator),
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check tokens are unlocked
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should still be in progress"
        );
        _verifyTokenLocking(address(token1), true);
        _verifyTokenLocking(address(token2), true);

        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            1 ether,
            "Locked balance for token1 should be 1 ether"
        );
        assertEq(
            caHook.retrieveLockedBalance(address(token2)),
            1 ether,
            "Locked balance for token2 should be 1 ether"
        );
    }

    // Test that unlocking tokens reverts if more tokens are trying to be unlocked than locked balance
    function test_unlockingTokens_singleExecute_revertIf_tryingToUnlockMoreThanLocked()
        public
    {
        // Set up the test environment
        _testSetup();
        token1.mint(address(mew), 1 ether);
        token1.approve(address(mew), 2 ether);
        // Set up SessionData
        bytes memory sessionData = _getDefaultSessionData();
        // Get enableSessionKey UserOperation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Set up calldata
        bytes memory callData = _createTokenTransferExecution(
            address(solver),
            2 ether
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_SINGLE, sessionKey),
                ExecutionLib.encodeSingle(address(token1), 0, callData)
            )
        );
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperation(
                address(mew),
                userOpCalldata,
                address(caValidator),
                sessionKeyPrivateKey
            );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the CredibleAccountHook_UnsuccessfulUnlock error to be emitted
        // wrapped in UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOps[0].nonce,
            abi.encodeWithSelector(
                CredibleAccountHook
                    .CredibleAccountHook_UnsuccessfulUnlock
                    .selector
            )
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check tokens are still locked and balances remain the same
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should be in progress"
        );
        _verifyTokenLocking(address(token1), true);
        _verifyTokenLocking(address(token2), true);
        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            1 ether,
            "Locked balance should remain same"
        );
        assertEq(
            caHook.retrieveLockedBalance(address(token2)),
            2 ether,
            "Locked balance should remain same"
        );
    }

    // Test that unlocking tokens works with a batch execute
    function test_unlockingTokens_batchExecute() public {
        // Set up the test environment
        _testSetup();
        // Set up SessionData
        bytes memory sessionData = _getDefaultSessionData();
        // Get enableSessionKey UserOperation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Set up calldata batch
        bytes memory token1Data = _createTokenTransferExecution(
            address(solver),
            1 ether
        );
        bytes memory token2Data = _createTokenTransferExecution(
            address(solver),
            2 ether
        );
        Execution[] memory batch = new Execution[](2);
        Execution memory token1Exec = Execution({
            target: address(token1),
            value: 0,
            callData: token1Data
        });
        Execution memory token2Exec = Execution({
            target: address(token2),
            value: 0,
            callData: token2Data
        });
        batch[0] = token1Exec;
        batch[1] = token2Exec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_BATCH, sessionKey),
                ExecutionLib.encodeBatch(batch)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(caValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        userOp.signature = _generateUserOpSignatureWithMerkleProof(
            userOp,
            sessionKeyPrivateKey
        );

        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check tokens are unlocked
        assertFalse(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should not be in progress"
        );
        _verifyTokenLocking(address(token1), false);
        _verifyTokenLocking(address(token2), false);
        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            0,
            "Locked balance should be 0"
        );
    }

    // Test that partial unlocking tokens works with a batch execute
    function test_partialUnlockingTokens_batchExecute() public {
        // Set up the test environment
        _testSetup();
        // Set up SessionData
        bytes memory sessionData = _getDefaultSessionData();
        // Get enableSessionKey UserOperation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute the user operation to lock tokens
        entrypoint.handleOps(userOps, beneficiary);
        // Set up calldata batch for partial unlocking
        bytes memory token1Data = _createTokenTransferExecution(
            address(solver),
            1 ether // Fully unlock token1
        );
        bytes memory token2Data = _createTokenTransferExecution(
            address(solver),
            1 ether // Partially unlock token2
        );
        Execution[] memory batch = new Execution[](2);
        Execution memory token1Exec = Execution({
            target: address(token1),
            value: 0,
            callData: token1Data
        });
        Execution memory token2Exec = Execution({
            target: address(token2),
            value: 0,
            callData: token2Data
        });
        batch[0] = token1Exec;
        batch[1] = token2Exec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_BATCH, sessionKey),
                ExecutionLib.encodeBatch(batch)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(caValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        userOp.signature = _generateUserOpSignatureWithMerkleProof(
            userOp,
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Execute the user operation to partially unlock tokens
        entrypoint.handleOps(userOps, beneficiary);
        // Check tokens are partially unlocked
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should still be in progress"
        );
        _verifyTokenLocking(address(token1), false);
        _verifyTokenLocking(address(token2), true);
        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            0,
            "Locked balance for token1 should be 0"
        );
        assertEq(
            caHook.retrieveLockedBalance(address(token2)),
            1 ether,
            "Locked balance for token2 should be 1 ether"
        );
    }

    // Test that multiple partial unlocking of same token
    // to completely unlock works with a batch execute
    function test_multiplePartialUnlockingTokens_batchExecute() public {
        // Set up the test environment
        _testSetup();
        // Set up SessionData
        bytes memory sessionData = _getDefaultSessionData();
        // Get enableSessionKey UserOperation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute the user operation to lock tokens
        entrypoint.handleOps(userOps, beneficiary);
        // Set up calldata batch for unlocking
        bytes memory token1Data = _createTokenTransferExecution(
            address(solver),
            1 ether // Fully unlock token1
        );
        bytes memory partialUnlockData = _createTokenTransferExecution(
            address(solver),
            1 ether // Partially unlock token2
        );
        bytes memory completeUnlockData = _createTokenTransferExecution(
            address(solver),
            1 ether // Completely unlock token2
        );

        Execution[] memory batch = new Execution[](3);
        Execution memory token1Exec = Execution({
            target: address(token1),
            value: 0,
            callData: token1Data
        });
        Execution memory partialUnlockExec = Execution({
            target: address(token2),
            value: 0,
            callData: partialUnlockData
        });
        Execution memory completeUnlockExec = Execution({
            target: address(token2),
            value: 0,
            callData: completeUnlockData
        });
        // Split up partial and complete unlocking transactions
        batch[0] = partialUnlockExec;
        batch[1] = token1Exec;
        batch[2] = completeUnlockExec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_BATCH, sessionKey),
                ExecutionLib.encodeBatch(batch)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(caValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        userOp.signature = _generateUserOpSignatureWithMerkleProof(
            userOp,
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Execute the user operation to unlock tokens
        entrypoint.handleOps(userOps, beneficiary);
        // Check tokens are completely unlocked
        assertFalse(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should not be in progress"
        );
        _verifyTokenLocking(address(token1), false);
        _verifyTokenLocking(address(token2), false);
        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            0,
            "Locked balance for token1 should be 0"
        );
        assertEq(
            caHook.retrieveLockedBalance(address(token2)),
            0,
            "Locked balance for token2 should be 1 ether"
        );
    }

    // Test that unlocking tokens reverts if the user tries to unlock more tokens than the locked balance
    function test_unlockingTokens_batchExecute_revertIf_tryingToUnlockMoreThanLocked()
        public
    {
        // Set up the test environment
        _testSetup();
        token1.mint(address(mew), 1 ether);
        token1.approve(address(mew), 2 ether);
        // Set up SessionData
        bytes memory sessionData = _getDefaultSessionData();
        // Get enableSessionKey UserOperation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Set up calldata batch
        bytes memory token1Data = _createTokenTransferExecution(
            address(solver),
            2 ether
        );
        Execution[] memory batch = new Execution[](1);
        Execution memory token1Exec = Execution({
            target: address(token1),
            value: 0,
            callData: token1Data
        });
        batch[0] = token1Exec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_BATCH, sessionKey),
                ExecutionLib.encodeBatch(batch)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(caValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        userOp.signature = _generateUserOpSignatureWithMerkleProof(
            userOp,
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the CredibleAccountHook_UnsuccessfulUnlock error to be emitted
        // wrapped in UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOps[0].nonce,
            abi.encodeWithSelector(
                CredibleAccountHook
                    .CredibleAccountHook_UnsuccessfulUnlock
                    .selector
            )
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check tokens are still locked and balances remain the same
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should be in progress"
        );
        _verifyTokenLocking(address(token1), true);
        _verifyTokenLocking(address(token2), true);
        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            1 ether,
            "Locked balance should remain the same"
        );
        assertEq(
            caHook.retrieveLockedBalance(address(token2)),
            2 ether,
            "Locked balance should remain the same"
        );
    }

    // Test that unlocking tokens reverts if the user tries to unlock tokens with an incorrect solver
    function test_unlockingTokens_batchExecute_revertIf_incorrectSolver()
        public
    {
        // Set up the test environment
        _testSetup();
        // Set up SessionData
        bytes memory sessionData = _getDefaultSessionData();
        // Get enableSessionKey UserOperation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Set up calldata batch with incorrect solver
        bytes memory token1Data = _createTokenTransferExecution(
            address(receiver),
            1 ether
        );
        Execution[] memory batch = new Execution[](1);
        Execution memory token1Exec = Execution({
            target: address(token1),
            value: 0,
            callData: token1Data
        });
        batch[0] = token1Exec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_BATCH, sessionKey),
                ExecutionLib.encodeBatch(batch)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(caValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        userOp.signature = _generateUserOpSignatureWithMerkleProof(
            userOp,
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the CredibleAccountHook_UnsuccessfulUnlock error to be emitted
        // wrapped in UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOps[0].nonce,
            abi.encodeWithSelector(
                CredibleAccountHook
                    .CredibleAccountHook_UnsuccessfulUnlock
                    .selector
            )
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check tokens are still locked and balances remain the same
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should be in progress"
        );
        _verifyTokenLocking(address(token1), true);
        _verifyTokenLocking(address(token2), true);
        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            1 ether,
            "Locked balance should remain the same"
        );
        assertEq(
            caHook.retrieveLockedBalance(address(token2)),
            2 ether,
            "Locked balance should remain the same"
        );
    }

    // Test that unlocking tokens reverts if the user tries to unlock tokens with an invalid session key
    function test_unlockingTokens_batchExecute_revertIf_invalidSessionKey()
        public
    {
        // Set up the test environment
        _testSetup();
        // Set up SessionData
        bytes memory sessionData = _getDefaultSessionData();
        // Get enableSessionKey UserOperation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Set up calldata batch with invalid session key
        bytes memory token1Data = _createTokenTransferExecution(
            address(solver),
            1 ether
        );
        Execution[] memory batch = new Execution[](1);
        Execution memory token1Exec = Execution({
            target: address(token1),
            value: 0,
            callData: token1Data
        });
        batch[0] = token1Exec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_BATCH, address(0xdeadface)),
                ExecutionLib.encodeBatch(batch)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(caValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        userOp.signature = _generateUserOpSignatureWithMerkleProof(
            userOp,
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the CredibleAccountHook_UnsuccessfulUnlock error to be emitted
        // wrapped in UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            hash,
            address(mew),
            userOps[0].nonce,
            abi.encodeWithSelector(
                CredibleAccountHook
                    .CredibleAccountHook_UnsuccessfulUnlock
                    .selector
            )
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check tokens are still locked and balances remain the same
        assertTrue(
            caHook.isTransactionInProgress(address(mew)),
            "Transaction should be in progress"
        );
        _verifyTokenLocking(address(token1), true);
        _verifyTokenLocking(address(token2), true);
        assertEq(
            caHook.retrieveLockedBalance(address(token1)),
            1 ether,
            "Locked balance should remain the same"
        );
        assertEq(
            caHook.retrieveLockedBalance(address(token2)),
            2 ether,
            "Locked balance should remain the same"
        );
    }

    /*//////////////////////////////////////////////////////////////
                      TESTS (INTERNAL FUNCTIONS)
    //////////////////////////////////////////////////////////////*/

    // Test the exposed function for getting token balance
    function test_exposed_getTokenBalance() public {
        // Set up the test environment
        _testSetup();
        // Get token balances using the exposed function
        uint256 balance1 = harness.exposed_getTokenBalance(address(token1));
        uint256 balance2 = harness.exposed_getTokenBalance(address(token2));
        // Verify that the token balances are correct
        assertEq(balance1, 1 ether, "Token 1 balance should be 1 ether");
        assertEq(balance2, 2 ether, "Token 2 balance should be 2 ether");
    }

    // Test the exposed function for locking tokens
    function test_exposed_lockTokens() public {
        // Set up the test environment
        _testSetup();
        // Prepare session data and encode it for the validator
        bytes memory sessionData = _getDefaultSessionData();
        bytes memory data = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            sessionData
        );
        // Execute the lockTokens function through the harness
        bool success = harness.exposed_lockTokens(data);
        // Verify that the tokens are successfully locked
        assertTrue(success, "Tokens should be locked successfully");
        assertTrue(
            harness.isTokenLocked(address(mew), address(token1)),
            "Token 1 should be locked"
        );
        assertTrue(
            harness.isTokenLocked(address(mew), address(token2)),
            "Token 2 should be locked"
        );
    }

    // Test that the exposed lockTokens function allows locking more of the same token if balance allows
    function test_exposed_lockTokens_shouldAllowMoreOfTokenToBeLockedIfBalanceAllows()
        public
    {
        // Set up the test environment
        _testSetup();
        // Lock initial tokens
        bytes memory sessionData = _getDefaultSessionData();
        bytes memory data = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            sessionData
        );
        bool success = harness.exposed_lockTokens(data);
        assertTrue(success, "Tokens should be locked successfully");
        assertTrue(
            harness.isTokenLocked(address(mew), address(token1)),
            "Token 1 should be locked"
        );
        assertTrue(
            harness.isTokenLocked(address(mew), address(token2)),
            "Token 2 should be locked"
        );
        // Prepare to lock more of the same token
        address anotherSessionKey = address(0x535510);
        token1.mint(address(mew), 13 ether);
        token1.approve(address(mew), 13 ether);
        // Generate new session data for additional token locking
        sessionData = abi.encodePacked(
            anotherSessionKey,
            solver,
            selector,
            validAfter,
            validUntil,
            uint256(1),
            [address(token1)],
            uint256(1),
            [13 ether]
        );
        data = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            sessionData
        );
        // Lock additional tokens
        success = harness.exposed_lockTokens(data);
        // Verify that additional tokens are locked
        assertTrue(success, "Tokens should be locked successfully");
        assertTrue(
            harness.isTokenLocked(address(mew), address(token1)),
            "Token 1 should still be locked"
        );
        uint256 totalLocked = harness.retrieveLockedBalance(address(token1));
        assertEq(
            totalLocked,
            14 ether,
            "Total locked balance should be cumulative amount"
        );
    }

    // Test that the exposed lockTokens function prevents locking more tokens if there's insufficient balance
    function test_exposed_lockTokens_shouldNotAllowMoreOfTokenToBeLockedIfInsufficientBalance()
        public
    {
        // Set up the test environment
        _testSetup();
        // Lock initial tokens
        bytes memory sessionData = _getDefaultSessionData();
        bytes memory data = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            sessionData
        );
        bool success = harness.exposed_lockTokens(data);
        assertTrue(success, "Tokens should be locked successfully");
        assertTrue(
            harness.isTokenLocked(address(mew), address(token1)),
            "Token 1 should be locked"
        );
        assertTrue(
            harness.isTokenLocked(address(mew), address(token2)),
            "Token 2 should be locked"
        );
        // Attempt to lock more tokens than available balance
        address anotherSessionKey = address(0x535510);
        token1.mint(address(mew), 12 ether);
        token1.approve(address(mew), 13 ether);
        // Generate new session data for additional token locking
        sessionData = abi.encodePacked(
            anotherSessionKey,
            solver,
            selector,
            validAfter,
            validUntil,
            uint256(1),
            [address(token1)],
            uint256(1),
            [13 ether]
        );
        data = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            sessionData
        );
        // Attempt to lock additional tokens
        success = harness.exposed_lockTokens(data);
        // Verify that locking additional tokens fails
        assertFalse(success, "Tokens should not be locked this time");
        assertTrue(
            harness.isTokenLocked(address(mew), address(token1)),
            "Token 1 should still be locked"
        );
        uint256 totalLocked = harness.retrieveLockedBalance(address(token1));
        assertEq(
            totalLocked,
            1 ether,
            "Total locked balance should remain the same"
        );
    }

    // Test the _unlockTokens function
    function test_exposed_unlockTokens() public {
        // Set up the test environment
        _testSetup();
        // Lock tokens first
        bytes memory sessionData = _getDefaultSessionData();
        bytes memory data = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            sessionData
        );
        bool lockSuccess = harness.exposed_lockTokens(data);
        assertTrue(lockSuccess, "Tokens should be locked successfully");

        // Attempt to unlock tokens
        bool unlockSuccess = harness.exposed_unlockTokens(
            sessionKey,
            address(token1),
            solver,
            0.5 ether
        );
        // Verify that tokens are successfully unlocked
        assertTrue(unlockSuccess, "Tokens should be unlocked successfully");
        assertEq(
            harness.retrieveLockedBalance(address(token1)),
            0.5 ether,
            "Remaining locked balance should be 0.5 ether"
        );
    }

    // Test the _digestERC20Transaction function
    function test_exposed_digestERC20Transaction() public {
        // Set up the test environment
        _testSetup();
        // Set up test data for transfer
        address recipient = address(0x123);
        uint256 amount = 1 ether;
        bytes memory transferData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            recipient,
            amount
        );
        // Call the exposed function
        (
            bytes4 selector,
            address digestedRecipient,
            uint256 digestedAmount
        ) = harness.exposed_digestERC20Transaction(transferData);
        // Verify the digested data
        assertEq(selector, IERC20.transfer.selector, "Selector should match");
        assertEq(digestedRecipient, recipient, "Recipient should match");
        assertEq(digestedAmount, amount, "Amount should match");
        // Test with transferFrom
        address from = address(0x456);
        bytes memory transferFromData = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            from,
            recipient,
            amount
        );
        (selector, digestedRecipient, digestedAmount) = harness
            .exposed_digestERC20Transaction(transferFromData);
        // Verify the digested data for transferFrom
        assertEq(
            selector,
            IERC20.transferFrom.selector,
            "Selector should match for transferFrom"
        );
        assertEq(
            digestedRecipient,
            recipient,
            "Recipient should match for transferFrom"
        );
        assertEq(
            digestedAmount,
            amount,
            "Amount should match for transferFrom"
        );
    }

    // Test the _encodeInitialLockedState function
    function test_exposed_encodeInitialLockedState() public {
        // Set up the test environment
        _testSetup();
        // Lock some tokens
        bytes memory sessionData = _getDefaultSessionData();
        bytes memory data = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            sessionData
        );
        bool lockSuccess = harness.exposed_lockTokens(data);
        assertTrue(lockSuccess, "Tokens should be locked successfully");
        // Call the exposed function
        bytes memory encodedState = harness.exposed_encodeInitialLockedState();
        // Decode the state
        ICAH.TokenBalance[] memory initialBalances = abi.decode(
            encodedState,
            (ICAH.TokenBalance[])
        );
        // Verify the encoded state
        assertEq(initialBalances.length, 2, "Should have 2 token balances");
        assertEq(
            initialBalances[0].token,
            address(token1),
            "First token should be token1"
        );
        assertEq(
            initialBalances[0].balance,
            1 ether,
            "Balance of token1 should be 1 ether"
        );
        assertEq(
            initialBalances[1].token,
            address(token2),
            "Second token should be token2"
        );
        assertEq(
            initialBalances[1].balance,
            2 ether,
            "Balance of token2 should be 2 ether"
        );
    }
}
