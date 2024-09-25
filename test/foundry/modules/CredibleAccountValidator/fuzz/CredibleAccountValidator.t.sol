// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ICredibleAccountValidator as ICAV} from "../../../../../src/modular-etherspot-wallet/interfaces/ICredibleAccountValidator.sol";
import {CredibleAccountValidatorTestUtils as CAV_TestUtils} from "../utils/CredibleAccountValidatorTestUtils.sol";
import "../../../TestAdvancedUtils.t.sol";
import "../../../../../account-abstraction/contracts/core/Helpers.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CredibleAccountValidator_Fuzz_Test is CAV_TestUtils {
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CredibleAccountValidator_SessionKeyEnabled(
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

    function testFuzz_enableSessionKey(
        uint48 validUntil,
        uint48 validAfter,
        bool useTransferSelector,
        uint256[3] memory fuzzedAmounts,
        address fuzzedSolver
    ) public {
        // Setup test environment
        _testSetup();
        // Ensure validUntil is in the future and within uint48 range
        validUntil = uint48(
            bound(
                uint256(validUntil),
                block.timestamp + 1 hours,
                type(uint48).max
            )
        );
        // Ensure validAfter is between now and validUntil
        validAfter = uint48(
            bound(uint256(validAfter), block.timestamp, uint256(validUntil) - 1)
        );
        // Set function selector based on fuzzed boolean
        bytes4 functionSelector = useTransferSelector
            ? IERC20.transfer.selector
            : IERC20.transferFrom.selector;
        // Set up fuzzed amounts and solver
        for (uint256 i; i < 3; ++i) {
            amounts[i] = bound(fuzzedAmounts[i], 1, type(uint256).max);
        }
        address tSolver = fuzzedSolver;
        vm.assume(tSolver != address(0) && tSolver != address(mew));
        // Mint and approve tokens
        usdc.mint(address(mew), amounts[0]);
        dai.mint(address(mew), amounts[1]);
        uni.mint(address(mew), amounts[2]);
        usdc.approve(address(mew), amounts[0]);
        dai.approve(address(mew), amounts[1]);
        uni.approve(address(mew), amounts[2]);
        // Enable session key
        bytes memory sessionData = abi.encodePacked(
            sessionKey,
            tSolver,
            functionSelector,
            validAfter,
            validUntil,
            TOKENS_LENGTH,
            tokens,
            AMOUNTS_LENGTH,
            amounts
        );
        vm.expectEmit(true, true, true, true);
        emit CredibleAccountValidator_SessionKeyEnabled(
            sessionKey,
            address(mew)
        );
        credibleAccountValidator.enableSessionKey(sessionData);
        // Validate session key data
        ICAV.SessionData memory sessionDataQueried = credibleAccountValidator
            .getSessionKeyData(sessionKey);
        assertEq(credibleAccountValidator.getAssociatedSessionKeys().length, 1);
        assertEq(sessionDataQueried.validUntil, validUntil);
        assertEq(sessionDataQueried.validAfter, validAfter);
        assertEq(sessionDataQueried.selector, functionSelector);
        assertTrue(
            sessionDataQueried.selector == IERC20.transfer.selector ||
                sessionDataQueried.selector == IERC20.transferFrom.selector
        );
        assertEq(sessionDataQueried.lockedTokens.length, tokens.length);
        assertEq(sessionDataQueried.lockedTokens.length, amounts.length);
        assertEq(sessionDataQueried.solver, tSolver);
        // Validate token balances
        assertEq(usdc.balanceOf(address(mew)), amounts[0]);
        assertEq(dai.balanceOf(address(mew)), amounts[1]);
        assertEq(uni.balanceOf(address(mew)), amounts[2]);
    }

    function testFuzz_e2e_handleUserOp(
        uint256[3] memory rawAmounts,
        address rawSolver
    ) public {
        // Generate valid transfer amounts
        uint256[] memory transferAmounts = new uint256[](AMOUNTS_LENGTH);
        for (uint256 i = 0; i < AMOUNTS_LENGTH; i++) {
            transferAmounts[i] = bound(rawAmounts[i], 1, 100 ether);
        }
        // Generate a valid solver address
        address fSolver = address(
            uint160(bound(uint256(uint160(rawSolver)), 1, type(uint160).max))
        );
        // Ensure fSolver is not wallet
        if (fSolver == address(mew)) {
            fSolver = address(uint160(fSolver) + 1);
        }
        // Set up the test environment
        _testSetup();
        // Mint fuzzed token amounts to wallet
        aave.mint(address(mew), transferAmounts[0]);
        dai.mint(address(mew), transferAmounts[1]);
        uni.mint(address(mew), transferAmounts[2]);
        aave.approve(address(mew), transferAmounts[0]);
        dai.approve(address(mew), transferAmounts[1]);
        uni.approve(address(mew), transferAmounts[2]);
        // Set up session key
        bytes memory sessionData = abi.encodePacked(
            sessionKey,
            fSolver,
            IERC20.transferFrom.selector,
            validAfter,
            validUntil,
            TOKENS_LENGTH,
            [address(aave), address(dai), address(uni)],
            AMOUNTS_LENGTH,
            transferAmounts
        );
        credibleAccountValidator.enableSessionKey(sessionData);
        // Prepare user operation and execution data
        Execution[] memory executions = new Execution[](3);
        bytes memory aaveData = _createTokenTransferFromExecution(
            address(mew),
            fSolver,
            transferAmounts[0]
        );
        bytes memory daiData = _createTokenTransferFromExecution(
            address(mew),
            fSolver,
            transferAmounts[1]
        );
        bytes memory uniData = _createTokenTransferFromExecution(
            address(mew),
            fSolver,
            transferAmounts[2]
        );
        executions[0] = Execution({
            target: address(aave),
            value: 0,
            callData: aaveData
        });
        executions[1] = Execution({
            target: address(dai),
            value: 0,
            callData: daiData
        });
        executions[2] = Execution({
            target: address(uni),
            value: 0,
            callData: uniData
        });
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            sessionKeyPrivateKey
        );
        // Record initial balances
        uint256 initialMewBalanceAAVE = aave.balanceOf(address(mew));
        uint256 initialMewBalanceDAI = dai.balanceOf(address(mew));
        uint256 initialMewBalanceUNI = uni.balanceOf(address(mew));
        // Execute the user operation
        _executeUserOperation(userOp);
        // Verify the token transfer
        assertEq(
            aave.balanceOf(fSolver),
            transferAmounts[0],
            "Recipient's AAVE balance should increase by the transferred amount"
        );
        assertEq(
            aave.balanceOf(address(mew)),
            initialMewBalanceAAVE - transferAmounts[0],
            "Mew's AAVE balance should decrease by the transferred amount"
        );
        assertEq(
            dai.balanceOf(fSolver),
            transferAmounts[1],
            "Recipient's DAI balance should increase by the transferred amount"
        );
        assertEq(
            dai.balanceOf(address(mew)),
            initialMewBalanceDAI - transferAmounts[1],
            "Mew's DAI balance should decrease by the transferred amount"
        );
        assertEq(
            uni.balanceOf(fSolver),
            transferAmounts[2],
            "Recipient's UNI balance should increase by the transferred amount"
        );
        assertEq(
            uni.balanceOf(address(mew)),
            initialMewBalanceUNI - transferAmounts[2],
            "Mew's UNI balance should decrease by the transferred amount"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HARNESS TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_digest(
        bool useApprovedSelector,
        address from,
        address to,
        uint256 amount
    ) public {
        // Setup test environment
        _testSetup();
        // Set function selector based on fuzzed boolean
        bytes4 selector;
        bytes memory data;
        if (useApprovedSelector) {
            if (from == address(0)) {
                selector = IERC20.transfer.selector;
                data = abi.encodeWithSelector(selector, to, amount);
            } else {
                selector = IERC20.transferFrom.selector;
                data = abi.encodeWithSelector(selector, from, to, amount);
            }
        } else {
            selector = bytes4(keccak256("invalidFunction(address,uint256)"));
            data = abi.encodeWithSelector(selector, to, amount);
        }
        // Validate digest
        (
            bytes4 resultSelector,
            address resultFrom,
            address resultTo,
            uint256 resultAmount
        ) = harness.exposed_digest(data);
        // Check digest dependant on fuzzed selector
        if (useApprovedSelector) {
            assertEq(resultSelector, selector);
            if (selector == IERC20.transfer.selector) {
                assertEq(resultFrom, address(0));
                assertEq(resultTo, to);
                assertEq(resultAmount, amount);
            } else {
                assertEq(resultFrom, from);
                assertEq(resultTo, to);
                assertEq(resultAmount, amount);
            }
        } else {
            assertEq(resultSelector, bytes4(0));
            assertEq(resultFrom, address(0));
            assertEq(resultTo, address(0));
            assertEq(resultAmount, 0);
        }
    }

    function testFuzz_digestSignature(uint256 randomLength) public {

        // Define assumptions
        // Bound the length to a reasonable range
        uint256 adjustedLength = bound(randomLength, 65, 1000);

        // Generate a random signature with merkle proof
        bytes memory fSignature = new bytes(adjustedLength);

        for (uint256 i; i < adjustedLength; ++i) {
            fSignature[i] = bytes1(
                uint8(bound(uint256(keccak256(abi.encodePacked(i))), 0, 255))
            );
        }

        // Setup test environment
        _testSetup();

        // Digest signature
        (
            bytes memory signature,
            bytes memory proof
        ) = harness.exposed_digestSignature(fSignature);

        // Verify signature components
        assertEq(signature.length, 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes32 signatureR;
        bytes32 signatureS;
        uint8 signatureV;
        assembly {
            r := mload(add(fSignature, 32))
            s := mload(add(fSignature, 64))
            v := byte(0, mload(add(fSignature, 65)))
            signatureR := mload(add(signature, 32))
            signatureS := mload(add(signature, 64))
            signatureV := byte(0, mload(add(signature, 65)))
        }
        assertEq(signatureR, r);
        assertEq(signatureS, s);
        assertEq(signatureV, v);

        // Verify proof
        uint256 expectedProofLength = (fSignature.length - 65);
        assertEq(proof.length, expectedProofLength);

        
    }
}
