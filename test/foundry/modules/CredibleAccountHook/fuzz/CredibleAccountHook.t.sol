// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CredibleAccountHook} from "../../../../../src/modular-etherspot-wallet/modules/hooks/CredibleAccountHook.sol";
import {CredibleAccountHookTestUtils} from "../utils/CredibleAccountHookTestUtils.sol";
import {TestERC20} from "../../../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Account.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ExecutionLib.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";

using ERC4337Utils for IEntryPoint;

contract CredibleAccountHook_Fuzz_Test is CredibleAccountHookTestUtils {
    using ModeLib for ModeCode;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();
        // Set up test environment
        _testSetup();
    }

    /*//////////////////////////////////////////////////////////////
                                TESTS
    //////////////////////////////////////////////////////////////*/

    // Test locking tokens
    function testFuzz_lockTokens(uint256 amount1, uint256 amount2) public {
        // Define assumptions
        vm.assume(amount1 > 0 && amount1 <= 1000 ether);
        vm.assume(amount2 > 0 && amount2 <= 1000 ether);
        // Mint and approve tokens
        token1.mint(address(mew), amount1);
        token2.mint(address(mew), amount2);
        token1.approve(address(mew), amount1);
        token2.approve(address(mew), amount2);
        // Create session key data
        bytes memory sessionData = abi.encodePacked(
            sessionKey,
            solver,
            selector,
            validAfter,
            validUntil,
            uint256(2),
            [address(token1), address(token2)],
            uint256(2),
            [amount1, amount2]
        );
        // Create enable session key user operation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Verify locked token information
        _verifyTokenLocking(address(token1), true);
        _verifyTokenLocking(address(token2), true);
        assertEq(
            credibleAccountHook.retrieveLockedBalance(address(token1)),
            amount1
        );
        assertEq(
            credibleAccountHook.retrieveLockedBalance(address(token2)),
            amount2
        );
    }

    // Test partial unlocking of tokens
    function testFuzz_partialUnlockTokens(
        uint256 lockAmount,
        uint256 unlockAmount
    ) public {
        // Define assumptions
        vm.assume(lockAmount > 0 && lockAmount <= 1000 ether);
        vm.assume(unlockAmount > 0 && unlockAmount < lockAmount);
        // Mint and approve tokens
        token1.mint(address(mew), lockAmount);
        token1.approve(address(mew), lockAmount);
        // Create session key data
        bytes memory sessionData = abi.encodePacked(
            sessionKey,
            solver,
            selector,
            validAfter,
            validUntil,
            uint256(1),
            [address(token1)],
            uint256(1),
            [lockAmount]
        );
        // Create enable session key user operation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Create token transfer data
        bytes memory callData = _createTokenTransferExecution(
            address(solver),
            unlockAmount
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_SINGLE, sessionKey),
                ExecutionLib.encodeSingle(address(token1), 0, callData)
            )
        );
        // Create enable session key user operation
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(credibleAccountValidator),
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Execute user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Verify locked token information
        _verifyTokenLocking(address(token1), true);
        assertEq(
            credibleAccountHook.retrieveLockedBalance(address(token1)),
            lockAmount - unlockAmount
        );
    }

    // Test unlocking tokens reverts if exceeds locked amount
    function testFuzz_unlockingTokens_revertIf_exceedsLockedAmount(
        uint256 lockAmount,
        uint256 unlockAmount
    ) public {
        // Define assumptions
        vm.assume(lockAmount > 0 && lockAmount <= 100 ether);
        vm.assume(unlockAmount > lockAmount && unlockAmount <= 100 ether);
        // Mint and approve tokens (unlockAmount to ensure balance > lock amount)
        token1.mint(address(mew), unlockAmount);
        token1.approve(address(mew), unlockAmount);
        // Create session key data
        bytes memory sessionData = abi.encodePacked(
            sessionKey,
            solver,
            selector,
            validAfter,
            validUntil,
            uint256(1),
            [address(token1)],
            uint256(1),
            [lockAmount]
        );
        // Set up enable session key user operation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute enable session key user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Setup the unlock operation with an amount greater than the locked amount
        bytes memory callData = _createTokenTransferExecution(
            address(solver),
            unlockAmount
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
                address(credibleAccountValidator),
                sessionKeyPrivateKey
            );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the operation to revert with CredibleAccountHook_UnsuccessfulUnlock error
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
        // Attempt to execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Ensure the transaction is reverted and initial state is maintained
        _verifyTokenLocking(address(token1), true);
        assertEq(
            credibleAccountHook.retrieveLockedBalance(address(token1)),
            lockAmount
        );
    }

    // Test batch unlocking tokens
    function testFuzz_batchUnlockTokens(
        uint256 rawLength,
        uint256[] memory rawAmounts
    ) public {
        // Generate a valid length
        uint256 length = bound(rawLength, 1, 5);
        // Generate valid amounts
        uint256[] memory amounts = new uint256[](length);
        uint256 totalAmount;
        for (uint256 i; i < length; ++i) {
            uint256 amount = bound(
                i < rawAmounts.length ? rawAmounts[i] : 0,
                1,
                100 ether
            );
            amounts[i] = amount;
            totalAmount += amount;
        }
        // Mint and approve tokens
        token1.mint(address(mew), totalAmount);
        token1.approve(address(mew), totalAmount);
        // Create session key data
        bytes memory sessionData = abi.encodePacked(
            sessionKey,
            solver,
            selector,
            validAfter,
            validUntil,
            uint256(1),
            [address(token1)],
            uint256(1),
            [totalAmount]
        );
        // Set up enable session key user operation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute enable session key user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Create batch executions
        Execution[] memory batch = new Execution[](amounts.length);
        for (uint256 i; i < amounts.length; ++i) {
            bytes memory callData = _createTokenTransferExecution(
                solver,
                amounts[i]
            );
            batch[i] = Execution({
                target: address(token1),
                value: 0,
                callData: callData
            });
        }
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_BATCH, sessionKey),
                ExecutionLib.encodeBatch(batch)
            )
        );
        // Create batch user operation
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(credibleAccountValidator),
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Execute user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Ensure the token is unlocked
        _verifyTokenLocking(address(token1), false);
        assertEq(credibleAccountHook.retrieveLockedBalance(address(token1)), 0);
    }

    // Test unlocking tokens with a different solvers
    function testFuzz_unlockTokensWithDifferentSolver(
        address fuzzedSolver
    ) public {
        // Define assumptions
        vm.assume(fuzzedSolver != address(0) && fuzzedSolver != solver);
        // Set locked amount
        uint256 lockAmount = 1 ether;
        // Mint and approve tokens
        token1.mint(address(mew), lockAmount);
        token1.approve(address(mew), lockAmount);
        // Create session key data
        bytes memory sessionData = abi.encodePacked(
            sessionKey,
            solver,
            selector,
            validAfter,
            validUntil,
            uint256(1),
            [address(token1)],
            uint256(1),
            [lockAmount]
        );
        // Set up enable session key user operation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute enable session key user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Create unlock user operation with different solver
        bytes memory callData = _createTokenTransferExecution(
            fuzzedSolver,
            lockAmount
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
                address(credibleAccountValidator),
                sessionKeyPrivateKey
            );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the transaction to be reverted with CredibleAccountHook_UnsuccessfulUnlock
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
        // Attempt to execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Verify initial state is maintained
        _verifyTokenLocking(address(token1), true);
        assertEq(
            credibleAccountHook.retrieveLockedBalance(address(token1)),
            lockAmount
        );
    }

    // Test unlocking tokens with a different selector
    // Restrict selectors to those that are not transfer or transferFrom
    // to avoid the possibility of a successful unlock
    function testFuzz_differentFunctionSelectors(bytes4 fuzzedSelector) public {
        // Define assumptions
        vm.assume(fuzzedSelector != bytes4(0));
        vm.assume(
            fuzzedSelector != IERC20.transfer.selector &&
                fuzzedSelector != IERC20.transferFrom.selector
        );
        // Set locked amount
        uint256 lockAmount = 1 ether;
        // Mint and approve tokens
        token1.mint(address(mew), lockAmount);
        token1.approve(address(mew), lockAmount);
        // Create session key data
        bytes memory sessionData = abi.encodePacked(
            sessionKey,
            solver,
            fuzzedSelector,
            validAfter,
            validUntil,
            uint256(1),
            [address(token1)],
            uint256(1),
            [lockAmount]
        );
        // Set up enable session key user operation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute enable session key user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Create unlock user operation with invalid selector
        bytes memory callData = abi.encodeWithSelector(
            fuzzedSelector,
            solver,
            lockAmount
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_SINGLE, sessionKey),
                ExecutionLib.encodeSingle(address(token1), 0, callData)
            )
        );
        // Create user operation
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(credibleAccountValidator),
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the operation to revert due to signature error (from validator)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operation
        entrypoint.handleOps(userOps, beneficiary);
    }

    // Test locking and unlocking with multiple tokens
    function testFuzz_multipleTokensLockUnlock(
        uint256 rawLength,
        uint256[] memory rawAmounts
    ) public {
        // Generate a valid length
        uint256 length = bound(rawLength, 2, 5);
        // Generate valid amounts
        uint256[] memory amounts = new uint256[](length);
        address[] memory tokens = new address[](length);
        uint256 totalAmount;
        for (uint256 i; i < length; ++i) {
            uint256 amount = bound(
                i < rawAmounts.length ? rawAmounts[i] : 0,
                1,
                100 ether
            );
            amounts[i] = amount;
            totalAmount += amount;
            // Create, mint, and approve new ERC20 tokens
            tokens[i] = address(new TestERC20());
            TestERC20(tokens[i]).mint(address(mew), amount);
            TestERC20(tokens[i]).approve(address(mew), amount);
        } // Create session key data
        bytes memory sessionData = abi.encodePacked(
            sessionKey,
            solver,
            selector,
            validAfter,
            validUntil,
            uint256(tokens.length),
            tokens,
            uint256(amounts.length),
            amounts
        );
        // Set up enable session key user operation
        (, PackedUserOperation[] memory userOps) = _enableSessionKeyUserOp(
            address(mew),
            _getLockingMode(CALLTYPE_SINGLE),
            sessionData,
            owner1Key
        );
        // Execute enable session key user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Verify tokens are locked
        for (uint256 i; i < tokens.length; ++i) {
            assertEq(
                credibleAccountHook.retrieveLockedBalance(tokens[i]),
                amounts[i]
            );
        }
        // Create batch of token transfer executions
        Execution[] memory batch = new Execution[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            bytes memory callData = _createTokenTransferExecution(
                solver,
                amounts[i]
            );
            batch[i] = Execution({
                target: tokens[i],
                value: 0,
                callData: callData
            });
        }
        // Create unlock user operation
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _getUnlockingMode(CALLTYPE_BATCH, sessionKey),
                ExecutionLib.encodeBatch(batch)
            )
        );
        // Create user operation
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(credibleAccountValidator),
            sessionKeyPrivateKey
        );
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Execute unlock user operation
        entrypoint.handleOps(userOps, beneficiary);
        // Verify tokens are unlocked
        for (uint256 i; i < tokens.length; ++i) {
            assertEq(credibleAccountHook.retrieveLockedBalance(tokens[i]), 0);
        }
    }
}
