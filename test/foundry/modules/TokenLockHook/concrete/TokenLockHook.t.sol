// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {ModularEtherspotWallet} from "../../../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {TokenLockHook} from "../../../../../src/modular-etherspot-wallet/modules/hooks/TokenLockHook.sol";
import {TokenLockHookTestUtils} from "../utils/TokenLockHookTestUtils.sol";
import {TestERC20} from "../../../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import {TestCounter} from "../../../../../src/modular-etherspot-wallet/test/TestCounter.sol";
import {MODULE_TYPE_HOOK} from "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ExecutionLib.sol";
import "../../../TestAdvancedUtils.t.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

using ERC4337Utils for IEntryPoint;

contract TokenLockHook_Concrete_Test is TokenLockHookTestUtils {
    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Contract instances
    TestERC20 internal erc20;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TLH_ModuleInstalled(address indexed wallet);
    event TLH_ModuleUninstalled(address indexed wallet);
    event TLH_TokenLocked(
        address indexed wallet,
        address indexed token,
        uint256 indexed amount
    );

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();
        erc20 = new TestERC20();
    }

    /*//////////////////////////////////////////////////////////////
                                TESTS
    //////////////////////////////////////////////////////////////*/

    function test_installModule() public {
        // Set up the Modular Etherspot Wallet
        mew = setupMEW();
        vm.startPrank(owner1);
        // Prepare the execution data for installing the module
        Execution[] memory batchCall = new Execution[](1);
        batchCall[0].target = address(mew);
        batchCall[0].value = 0;
        batchCall[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(4),
            address(tokenLockHook),
            hex""
        );
        // Expect the module installation event to be emitted
        vm.expectEmit(true, false, false, false);
        emit TLH_ModuleInstalled(address(mew));
        // Execute the module installation
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall);
        // Verify that the module is installed
        assertTrue(
            mew.isModuleInstalled(4, address(tokenLockHook), ""),
            "TokenLockHook module should be installed"
        );
    }

    function test_installModule_whileHookIsActive() public {
        // Set up the test environment
        _testSetup();
        // Set up new validator to install
        MockValidator newValidator = new MockValidator();
        // Prepare the execution data for installing the module
        // Execute the module installation
        defaultExecutor.executeViaAccount(
            IERC7579Account(mew),
            address(mew),
            0,
            abi.encodeWithSelector(
                ModularEtherspotWallet.installModule.selector,
                uint256(1),
                address(newValidator),
                ""
            )
        );
        // Verify that the module is installed
        assertTrue(
            mew.isModuleInstalled(1, address(newValidator), ""),
            "Validator module should be installed"
        );
    }

    function test_uninstallModule_whileHookIsActive() public {
        // Set up the test environment
        _testSetup();
        // Check to make sure hook is installed on wallet
        assertTrue(
            mew.isModuleInstalled(4, address(tokenLockHook), ""),
            "TokenLockHook module should be installed"
        );
        // Expect the module installation event to be emitted
        vm.expectEmit(true, false, false, false);
        emit TLH_ModuleUninstalled(address(mew));
        // Execute the module uninstallation
        defaultExecutor.executeViaAccount(
            IERC7579Account(mew),
            address(mew),
            0,
            abi.encodeWithSelector(
                ModularEtherspotWallet.uninstallModule.selector,
                uint256(4),
                address(tokenLockHook),
                ""
            )
        );
        // Verify that module is uninstalled
        assertFalse(
            mew.isModuleInstalled(4, address(tokenLockHook), ""),
            "TokenLockHook module should be uninstalled"
        );
    }

    // TODO: Add tests for:
    // - uninstallModule: reverts until transactionInProgress is false
    function test_uninstallModule_RevertIf_transactionInProgress() public {
        // Set up the test environment
        _testSetup();
        erc20.mint(address(mew), 2 ether);
        erc20.approve(address(mew), 2 ether);
        // Set up UserOperation
        (, PackedUserOperation[] memory userOps) = _singleLockTokenInHook(
            address(mew),
            address(receiver),
            address(erc20),
            1 ether,
            owner1Key,
            SelectMode.LOCKING_MODE
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        assertTrue(tokenLockHook.isTransactionInProgress());
        // Expect the function call to revert with TLH_CantUninstallWhileTransactionInProgress error
        // when trying uninstall hook when transaction in progress
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenLockHook
                    .TLH_CantUninstallWhileTransactionInProgress
                    .selector,
                address(mew)
            )
        );
        // Attempt module uninstallation
        defaultExecutor.executeViaAccount(
            IERC7579Account(mew),
            address(mew),
            0,
            abi.encodeWithSelector(
                ModularEtherspotWallet.uninstallModule.selector,
                uint256(4),
                address(tokenLockHook),
                ""
            )
        );
        // Unlock the token to allow for uninstall
        tokenLockHook.unlockToken(address(mew), address(erc20));
        // Attempt module uninstallation - should succeed
        defaultExecutor.executeViaAccount(
            IERC7579Account(mew),
            address(mew),
            0,
            abi.encodeWithSelector(
                ModularEtherspotWallet.uninstallModule.selector,
                uint256(4),
                address(tokenLockHook),
                ""
            )
        );
        // Check module is uninstalled
        assertFalse(tokenLockHook.isInitialized(address(mew)));
    }

    function test_isInitialized() public {
        // Set up the test environment
        _testSetup();
        assertTrue(tokenLockHook.isInitialized(address(mew)));
    }

    function test_isModuleType() public {
        assertTrue(tokenLockHook.isModuleType(4)); // 3 is MODULE_TYPE_HOOK
        assertFalse(tokenLockHook.isModuleType(1));
    }

    function test_preCheck_ifMultiTokenSessionKeyValidator_lockTokens_singleExecute()
        public
    {
        // Set up the test environment
        _testSetup();
        erc20.mint(address(mew), 2 ether);
        erc20.approve(address(mew), 1 ether);
        // Set up UserOperation
        (, PackedUserOperation[] memory userOps) = _singleLockTokenInHook(
            address(mew),
            address(receiver),
            address(erc20),
            1 ether,
            owner1Key,
            SelectMode.LOCKING_MODE
        );
        // Expect the TLH_TokenLocked event to be emitted
        vm.expectEmit(true, true, true, false);
        emit TLH_TokenLocked(address(mew), address(erc20), 1 ether);
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check receiver balance
        assertEq(erc20.balanceOf(address(receiver)), 1 ether);
    }

    function test_preCheck_ifMultiTokenSessionKeyValidator_lockTokens_batchExecute()
        public
    {
        // Set up the test environment
        _testSetup();
        TestERC20 newErc20 = new TestERC20();
        erc20.mint(address(mew), 2 ether);
        newErc20.mint(address(mew), 2 ether);
        erc20.approve(address(mew), 1 ether);
        newErc20.approve(address(mew), 2 ether);
        // Set up the execution data
        Execution[] memory batchCall = new Execution[](2);
        batchCall[0].target = address(erc20);
        batchCall[0].value = 0;
        batchCall[0].callData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            address(receiver),
            1 ether
        );
        batchCall[1].target = address(newErc20);
        batchCall[1].value = 0;
        batchCall[1].callData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            address(receiver),
            2 ether
        );
        // Set up UserOperation
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
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the TLH_TokenLocked event to be emitted
        vm.expectEmit(true, true, true, false);
        emit TLH_TokenLocked(address(mew), address(erc20), 1 ether);
        vm.expectEmit(true, true, true, false);
        emit TLH_TokenLocked(address(mew), address(newErc20), 2 ether);
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check receiver balance
        assertEq(erc20.balanceOf(address(receiver)), 1 ether);
        assertEq(newErc20.balanceOf(address(receiver)), 2 ether);
        assertTrue(tokenLockHook.isTokenLocked(address(mew), address(erc20)));
        assertTrue(tokenLockHook.isTokenLocked(address(mew), address(newErc20)));
        assertTrue(tokenLockHook.isTransactionInProgress());
    }

    function test_preCheck_ifMultiTokenSessionKeyValidator_RevertIf_alreadyLocked()
        public
    {
        // Set up the test environment
        _testSetup();
        erc20.mint(address(mew), 2 ether);
        erc20.approve(address(mew), 2 ether);
        // Set up UserOperation
        (, PackedUserOperation[] memory userOps) = _singleLockTokenInHook(
            address(mew),
            address(receiver),
            address(erc20),
            1 ether,
            owner1Key,
            SelectMode.LOCKING_MODE
        );
        // Expect the TLH_TokenLocked event to be emitted
        vm.expectEmit(true, true, true, false);
        emit TLH_TokenLocked(address(mew), address(erc20), 1 ether);
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check receiver balance
        assertEq(erc20.balanceOf(address(receiver)), 1 ether);
        // Get new UserOperation data with same calldata
        (
            bytes32 userOp1Hash,
            PackedUserOperation[] memory userOps1
        ) = _singleLockTokenInHook(
                address(mew),
                address(receiver),
                address(erc20),
                1 ether,
                owner1Key,
                SelectMode.LOCKING_MODE
            );
        // Expect the TLH_TransactionInProgress error to be emitted
        // wrapped in UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            userOp1Hash,
            address(mew),
            userOps1[0].nonce,
            abi.encodeWithSelector(
                TokenLockHook.TLH_TransactionInProgress.selector,
                address(mew),
                address(erc20)
            )
        );
        // Execute the user operation again
        entrypoint.handleOps(userOps1, beneficiary);
    }

    function test_preCheck_ifOtherValidator_shouldNotLockTokens() public {
        // Set up the test environment
        _testSetup();
        erc20.mint(address(mew), 2 ether);
        erc20.approve(address(mew), 1 ether);
        // Set up UserOperation
        (, PackedUserOperation[] memory userOps) = _singleLockTokenInHook(
            address(mew),
            address(receiver),
            address(erc20),
            1 ether,
            owner1Key,
            SelectMode.SINGLE_MODE
        );
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check receiver balance
        assertEq(erc20.balanceOf(address(receiver)), 1 ether);
        // Check tokens are not locked
        assertFalse(tokenLockHook.isTokenLocked(address(mew), address(erc20)));
    }

    function test_preCheck_ifOtherValidator_RevertIf_tokensAreLocked() public {
        // Set up the test environment
        _testSetup();
        erc20.mint(address(mew), 2 ether);
        erc20.approve(address(mew), 1 ether);
        // Set up UserOperation
        (, PackedUserOperation[] memory userOps) = _singleLockTokenInHook(
            address(mew),
            address(receiver),
            address(erc20),
            1 ether,
            owner1Key,
            SelectMode.LOCKING_MODE
        );
        // Expect the TLH_TokenLocked event to be emitted
        vm.expectEmit(true, true, true, false);
        emit TLH_TokenLocked(address(mew), address(erc20), 1 ether);
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Set up UserOperation
        (
            bytes32 userOpHash1,
            PackedUserOperation[] memory userOps1
        ) = _singleLockTokenInHook(
                address(mew),
                address(receiver),
                address(erc20),
                1 ether,
                owner1Key,
                SelectMode.SINGLE_MODE
            );
        // Expect the TLH_TransactionInProgress error to be emitted
        // wrapped in UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit IEntryPoint.UserOperationRevertReason(
            userOpHash1,
            address(mew),
            userOps1[0].nonce,
            abi.encodeWithSelector(
                TokenLockHook.TLH_TransactionInProgress.selector,
                address(mew),
                address(erc20)
            )
        );
        // Execute the user operation again
        entrypoint.handleOps(userOps1, beneficiary);
    }

    // TODO: test to check other transactions for tokens that are not locked proceed
    function test_preCheck_ifOtherValidator_allowOtherTransactions() public {
        // Set up the test environment
        _testSetup();
        TestCounter counter = new TestCounter();
        // Set up calldata
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.changeCount.selector,
            7579
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(counter), 0, callData)
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
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Check count value updated
        assertEq(counter.getCount(), 7579);
    }

    /*//////////////////////////////////////////////////////////////
                      TESTS (INTERNAL FUNCTIONS)
    //////////////////////////////////////////////////////////////*/

    function test_exposed_lockToken() public {
        // Set up the token lock variables
        address token = address(0x1234);
        uint256 amount = 99;
        // Set up the test environment
        _testSetup();
        // Expect the TLH_TokenLocked event to be emitted on locking token
        vm.expectEmit(true, true, true, false);
        emit TLH_TokenLocked(address(mew), token, amount);
        // Execute the lockToken function
        harness.exposed_lockToken(token, amount);
        // Check that the token is locked
        assertTrue(harness.isTokenLocked(address(mew), token));
    }

    function test_exposed_lockToken_RevertIf_tokenAlreadyLocked() public {
        // Set up the token lock variables
        address token = address(0x1234);
        uint256 amount = 99;
        // Set up the test environment
        _testSetup();
        // Lock the token
        harness.exposed_lockToken(token, amount);
        // Expect the function call to revert with TLH_TransactionInProgress error
        // when trying to lock an already locked token
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenLockHook.TLH_TransactionInProgress.selector,
                address(mew),
                token
            )
        );
        // Attempt to lock the token
        harness.exposed_lockToken(token, 13);
    }

    function test_exposed_handleMultiTokenSessionKeyValidator_callTypeSingle()
        public
    {
        // Set up the test environment
        _testSetup();
        // Set up the CallType
        CallType callType = CALLTYPE_SINGLE;
        // Set up the execution data
        bytes memory callData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            receiver,
            1 ether
        );
        bytes memory execution = ExecutionLib.encodeSingle(
            address(erc20),
            0,
            callData
        );
        // Expect the TLH_TokenLocked event to be emitted on locking token
        vm.expectEmit(true, true, true, false);
        emit TLH_TokenLocked(address(mew), address(erc20), 1 ether);
        // Execute the handleMultiTokenSessionKeyValidator function
        harness.exposed_handleMultiTokenSessionKeyValidator(
            callType,
            execution
        );
        // Check that the token is locked
        assertTrue(harness.isTokenLocked(address(mew), address(erc20)));
    }

    function test_exposed_handleMultiTokenSessionKeyValidator_callTypeBatch()
        public
    {
        // Set up the test environment
        _testSetup();
        TestERC20 newERC20 = new TestERC20();
        // Set up the CallType
        CallType callType = CALLTYPE_BATCH;
        // Set up the execution data
        Execution[] memory batchCall = new Execution[](2);
        batchCall[0].target = address(erc20);
        batchCall[0].value = 0;
        batchCall[0].callData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            receiver,
            1 ether
        );
        batchCall[1].target = address(newERC20);
        batchCall[1].value = 0;
        batchCall[1].callData = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            receiver,
            2 ether
        );
        bytes memory batchExecutions = ExecutionLib.encodeBatch(batchCall);
        // Expect the TLH_TokenLocked event to be emitted on locking token
        vm.expectEmit(true, true, true, false);
        emit TLH_TokenLocked(address(mew), address(erc20), 1 ether);
        // Expect the TLH_TokenLocked event to be emitted on locking token
        vm.expectEmit(true, true, true, false);
        emit TLH_TokenLocked(address(mew), address(newERC20), 2 ether);
        // Execute the handleMultiTokenSessionKeyValidator function
        harness.exposed_handleMultiTokenSessionKeyValidator(
            callType,
            batchExecutions
        );
        // Check that the Tokens are locked
        assertTrue(harness.isTokenLocked(address(mew), address(erc20)));
        assertTrue(harness.isTokenLocked(address(mew), address(newERC20)));
    }

    function test_exposed_handleMultiTokenSessionKeyValidator_RevertIf_invalidCallType()
        public
    {
        // Set up the test environment
        _testSetup();
        // Set up the CallType
        CallType callType = CALLTYPE_DELEGATECALL;
        // Set up the execution data
        bytes memory callData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            receiver,
            1 ether
        );
        bytes memory execution = ExecutionLib.encodeSingle(
            address(erc20),
            0,
            callData
        );
        // Expect the function call to revert with TLH_InvalidCallType error
        // when trying to use an unsupported CallType
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenLockHook.TLH_InvalidCallType.selector,
                callType
            )
        );
        // Execute the handleMultiTokenSessionKeyValidator function
        harness.exposed_handleMultiTokenSessionKeyValidator(
            callType,
            execution
        );
        // Check that the token is not locked
        assertFalse(harness.isTokenLocked(address(mew), address(erc20)));
    }

    function test_exposed_handleMultiTokenSessionKeyValidator_RevertIf_doubleLockingTokenInBatch()
        public
    {
        // Set up the test environment
        _testSetup();
        // Set up the CallType
        CallType callType = CALLTYPE_BATCH;
        // Set up the execution data
        Execution[] memory batchCall = new Execution[](2);
        batchCall[0].target = address(erc20);
        batchCall[0].value = 0;
        batchCall[0].callData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            receiver,
            1 ether
        );
        batchCall[1].target = address(erc20);
        batchCall[1].value = 0;
        batchCall[1].callData = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            receiver,
            2 ether
        );
        bytes memory batchExecutions = ExecutionLib.encodeBatch(batchCall);
        // Expect the function call to revert with TLH_TransactionInProgress error
        // when trying to lock a token twice in same batch
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenLockHook.TLH_TransactionInProgress.selector,
                address(mew),
                address(erc20)
            )
        );
        // Execute the handleMultiTokenSessionKeyValidator function
        harness.exposed_handleMultiTokenSessionKeyValidator(
            callType,
            batchExecutions
        );
        // Check that the token is not locked
        assertFalse(harness.isTokenLocked(address(mew), address(erc20)));
    }

    function test_exposed_checkLockedTokens_RevertIf_invalidCallType() public {
        // Set up the test environment
        _testSetup();
        // Set up the CallType
        CallType callType = CALLTYPE_DELEGATECALL;
        // Set up the execution data
        bytes memory callData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            receiver,
            1 ether
        );
        bytes memory execution = ExecutionLib.encodeSingle(
            address(erc20),
            0,
            callData
        );
        // Expect the function call to revert with TLH_InvalidCallType error
        // when trying to use an unsupported CallType
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenLockHook.TLH_InvalidCallType.selector,
                callType
            )
        );
        // Execute the checkLockedTokens function
        harness.exposed_checkLockedTokens(callType, execution);
    }

    function test_exposed_checkLockedTokens_callTypeSingle_RevertIf_tokenIsLocked()
        public
    {
        // Set up the test environment
        _testSetup();
        // Set up the CallType
        CallType callType = CALLTYPE_SINGLE;
        // Set up the execution data
        bytes memory callData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            receiver,
            1 ether
        );
        bytes memory execution = ExecutionLib.encodeSingle(
            address(erc20),
            0,
            callData
        );
        // Execute the handleMultiTokenSessionKeyValidator function
        harness.exposed_handleMultiTokenSessionKeyValidator(
            callType,
            execution
        );
        // Expect the function call to revert with TLH_TransactionInProgress error
        // if the token is locked
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenLockHook.TLH_TransactionInProgress.selector,
                address(mew),
                address(erc20)
            )
        );
        // Execute the checkLockedTokens function
        harness.exposed_checkLockedTokens(callType, execution);
    }

    function test_exposed_checkLockedTokens_callTypeBatch_RevertIf_tokenIsLocked()
        public
    {
        // Set up the test environment
        _testSetup();
        TestERC20 newERC20 = new TestERC20();
        // Set up the CallType
        CallType callType = CALLTYPE_BATCH;
        // Set up the execution data
        Execution[] memory batchCall = new Execution[](2);
        batchCall[0].target = address(erc20);
        batchCall[0].value = 0;
        batchCall[0].callData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            receiver,
            1 ether
        );
        batchCall[1].target = address(newERC20);
        batchCall[1].value = 0;
        batchCall[1].callData = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            receiver,
            2 ether
        );
        bytes memory batchExecutions = ExecutionLib.encodeBatch(batchCall);
        // Lock one of the tokens
        harness.exposed_lockToken(receiver, address(erc20), 1);
        // Check that the locked token is locked
        assertTrue(harness.isTokenLocked(address(mew), address(erc20)));
        // Expect the function call to revert with TLH_TransactionInProgress error
        // if one of the Tokens is locked
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenLockHook.TLH_TransactionInProgress.selector,
                address(mew),
                address(erc20)
            )
        );
        // Execute the checkLockedTokens function
        harness.exposed_checkLockedTokens(callType, batchExecutions);
        // Check that the locked token is still locked
        assertTrue(harness.isTokenLocked(address(mew), address(erc20)));
        // Check that the other token is not locked
        assertFalse(harness.isTokenLocked(address(mew), address(newERC20)));
    }

    function test_exposed_getTokenAmount_transfer() public {
        // Set up the test environment
        _testSetup();
        // Set up calldata
        bytes memory data = abi.encodeWithSelector(
            IERC20.transfer.selector,
            receiver,
            7579
        );
        // Call getTokenAmount to get amount of tokens
        uint256 amount = harness.exposed_getTokenAmount(data);
        // Check token amount retrieved from data is correct
        assertEq(amount, 7579);
    }

    function test_exposed_getTokenAmount_transferFrom() public {
        // Set up the test environment
        _testSetup();
        // Set up calldata
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            receiver,
            7579
        );
        // Call getTokenAmount to get amount of tokens
        uint256 amount = harness.exposed_getTokenAmount(data);
        // Check token amount retrieved from data is correct
        assertEq(amount, 7579);
    }

    function test_exposed_getTokenAmount_unsupportedSelector() public {
        // Set up the test environment
        _testSetup();
        // Set up calldata with unsupported selector
        bytes memory data = abi.encodeWithSelector(
            IERC20.approve.selector,
            receiver,
            7579
        );
        // Call getTokenAmount to get amount of tokens
        uint256 amount = harness.exposed_getTokenAmount(data);
        // Check token amount retrieved from data is zero
        assertEq(amount, 0);
    }

    /*//////////////////////////////////////////////////////////////
                                 TODO
    //////////////////////////////////////////////////////////////*/

    // TODO: check what happens if locking tokens but also calling uninstallModule in same batch
    // may need to lock this to CALLTYPE_SINGLE - locked for now

    // function testPreCheckMultiTokenSessionKeyValidator() public {
    //     ModeCode mode = ModeCode.wrap(
    //         bytes32(
    //             abi.encodePacked(
    //                 CALLTYPE_SINGLE,
    //                 ExecType.wrap(0x00),
    //                 bytes4(0),
    //                 ModeSelector.wrap(
    //                     bytes4(
    //                         keccak256(
    //                             "modularetherspotwallet.multitokensessionkeyvalidator"
    //                         )
    //                     )
    //                 ),
    //                 bytes22(0)
    //             )
    //         )
    //     );

    //     bytes memory executionData = abi.encodeWithSelector(
    //         bytes4(keccak256("transfer(address,uint256)")),
    //         address(0xdead),
    //         1 ether
    //     );

    //     bytes memory msgData = abi.encodePacked(
    //         bytes4(keccak256("execute(bytes32,bytes)")),
    //         mode,
    //         executionData
    //     );

    //     vm.expectEmit(true, true, true, true);
    //     emit ResourceLocked(address(this), mockToken, 1 ether);

    //     hook.preCheck(address(this), msgData);

    //     assertTrue(hook.checkIfLocked(mockToken));
    // }

    // function testPreCheckOtherValidator() public {
    //     ModeCode mode = ModeCode.wrap(
    //         bytes32(
    //             abi.encodePacked(
    //                 CALLTYPE_SINGLE,
    //                 ExecType.wrap(0x00),
    //                 bytes4(0),
    //                 ModeSelector.wrap(bytes4(keccak256("other.validator"))),
    //                 bytes22(0)
    //             )
    //         )
    //     );

    //     bytes memory executionData = abi.encodeWithSelector(
    //         bytes4(keccak256("transfer(address,uint256)")),
    //         address(0xdead),
    //         1 ether
    //     );

    //     bytes memory msgData = abi.encodePacked(
    //         bytes4(keccak256("execute(bytes32,bytes)")),
    //         mode,
    //         executionData
    //     );

    //     hook.preCheck(address(this), msgData);

    //     assertFalse(hook.checkIfLocked(mockToken));
    // }

    // function testPreCheckLockedResourceRevert() public {
    //     // First, lock a resource
    //     testPreCheckMultiTokenSessionKeyValidator();

    //     // Now try to use the locked resource with a different validator
    //     ModeCode mode = ModeCode.wrap(
    //         bytes32(
    //             abi.encodePacked(
    //                 CALLTYPE_SINGLE,
    //                 ExecType.wrap(0x00),
    //                 bytes4(0),
    //                 ModeSelector.wrap(bytes4(keccak256("other.validator"))),
    //                 bytes22(0)
    //             )
    //         )
    //     );

    //     bytes memory executionData = abi.encodeWithSelector(
    //         bytes4(keccak256("transfer(address,uint256)")),
    //         address(0xdead),
    //         1 ether
    //     );

    //     bytes memory msgData = abi.encodePacked(
    //         bytes4(keccak256("execute(bytes32,bytes)")),
    //         mode,
    //         executionData
    //     );

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             TokenLockHook.TransactionInProgress.selector,
    //             address(this),
    //             mockToken
    //         )
    //     );
    //     hook.preCheck(address(this), msgData);
    // }

    // function testBatchExecution() public {
    //     ModeCode mode = ModeCode.wrap(
    //         bytes32(
    //             abi.encodePacked(
    //                 CALLTYPE_BATCH,
    //                 ExecType.wrap(0x00),
    //                 bytes4(0),
    //                 ModeSelector.wrap(
    //                     bytes4(
    //                         keccak256(
    //                             "modularetherspotwallet.multitokensessionkeyvalidator"
    //                         )
    //                     )
    //                 ),
    //                 bytes22(0)
    //             )
    //         )
    //     );

    //     Execution[] memory executions = new Execution[](2);
    //     executions[0] = Execution(
    //         mockToken,
    //         0,
    //         abi.encodeWithSelector(
    //             bytes4(keccak256("transfer(address,uint256)")),
    //             address(0xdead),
    //             1 ether
    //         )
    //     );
    //     executions[1] = Execution(
    //         address(0x9876),
    //         0,
    //         abi.encodeWithSelector(
    //             bytes4(keccak256("transfer(address,uint256)")),
    //             address(0xbeef),
    //             2 ether
    //         )
    //     );

    //     bytes memory executionData = ExecutionLib.encodeBatch(executions);

    //     bytes memory msgData = abi.encodePacked(
    //         bytes4(keccak256("execute(bytes32,bytes)")),
    //         mode,
    //         executionData
    //     );

    //     vm.expectEmit(true, true, true, true);
    //     emit ResourceLocked(address(this), mockToken, 1 ether);
    //     vm.expectEmit(true, true, true, true);
    //     emit ResourceLocked(address(this), address(0x9876), 2 ether);

    //     hook.preCheck(address(this), msgData);

    //     assertTrue(hook.checkIfLocked(mockToken));
    //     assertTrue(hook.checkIfLocked(address(0x9876)));
    // }
}
