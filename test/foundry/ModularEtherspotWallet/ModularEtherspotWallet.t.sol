// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import {MockValidator} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockValidator.sol";
import {MockExecutor} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockExecutor.sol";
import {MockTarget} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockTarget.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/Bootstrap.t.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";
import {IAccountConfig, IAccountConfig_Hook, IModularEtherspotWallet, IExecution} from "../../../src/modular-etherspot-wallet/interfaces/IModularEtherspotWallet.sol";
import {ModularEtherspotWallet} from "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {ModularEtherspotWalletFactory} from "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";
import {MultipleOwnerECDSAValidator} from "../../../src/modular-etherspot-wallet/modules/MultipleOwnerECDSAValidator.sol";
import "../TestBaseUtil.t.sol";
import {ECDSA} from "solady/src/utils/ECDSA.sol";

contract ModularEtherspotWalletTest is TestBaseUtil {
    bytes32 immutable SALT = bytes32("TestSALT");
    ModularEtherspotWallet mew;

    address owner2;
    uint256 owner2Key;
    address guardian1;
    uint256 guardian1Key;
    address guardian2;
    uint256 guardian2Key;
    address guardian3;
    uint256 guardian3Key;
    address guardian4;
    uint256 guardian4Key;
    address badActor;
    uint256 badActorKey;

    // Event declarations (needed for vm.expectEmit)
    event OwnerAdded(address account, address added);
    event OwnerRemoved(address account, address removed);
    event GuardianAdded(address account, address newGuardian);
    event GuardianRemoved(address account, address removedGuardian);
    event ProposalTimelockChanged(address account, uint256 newTimelock);
    event ProposalSubmitted(
        address account,
        uint256 proposalId,
        address newOwnerProposed,
        address proposer
    );
    event QuorumNotReached(
        address account,
        uint256 proposalId,
        address newOwnerProposed,
        uint256 approvalCount
    );
    event ProposalDiscarded(
        address account,
        uint256 proposalId,
        address discardedBy
    );

    // Error declarations (needed for vm.expectRevert)
    error OnlyOwnerOrSelf();
    error AddingInvalidOwner();
    error RemovingInvalidOwner();
    error WalletNeedsOwner();
    error AddingInvalidGuardian();
    error RemovingInvalidGuardian();
    error OnlyGuardian();
    error NotEnoughGuardians();
    error ProposalUnresolved();
    error InvalidProposal();
    error AlreadySignedProposal();
    error ProposalResolved();
    error ProposalTimelocked();
    error OnlyOwnerOrGuardianOrSelf();

    function setUp() public override {
        super.setUp();
        (owner2, owner2Key) = makeAddrAndKey("owner2");
        (guardian1, guardian1Key) = makeAddrAndKey("guardian1");
        (guardian2, guardian2Key) = makeAddrAndKey("guardian2");
        (guardian3, guardian3Key) = makeAddrAndKey("guardian3");
        (guardian4, guardian4Key) = makeAddrAndKey("guardian4");
        (badActor, badActorKey) = makeAddrAndKey("badActor");
    }

    function test_execSingleMEW() public returns (address) {
        // Create calldata for the account to execute
        bytes memory setValueOnTarget = abi.encodeCall(
            MockTarget.setValue,
            1337
        );
        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(
                    address(target),
                    uint256(0),
                    setValueOnTarget
                )
            )
        );
        // Get the account, initcode and nonce
        (address account, bytes memory initCode) = getMEWAndInitCode();
        uint256 nonce = getNonce(account, address(ecdsaValidator));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(account);
        userOp.nonce = nonce;
        userOp.initCode = initCode;
        userOp.callData = userOpCalldata;

        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            owner1Key,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Send the userOp to the entrypoint
        entrypoint.handleOps(userOps, payable(address(0x69)));

        // Assert that the value was set ie that execution was successful
        assertTrue(target.value() == 1337);
        return account;
    }

    function test_execBatch() public {
        // Create calldata for the account to execute
        bytes memory setValueOnTarget = abi.encodeCall(
            MockTarget.setValue,
            1337
        );
        address target2 = address(0x420);
        uint256 target2Amount = 1 wei;

        // Create the executions
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution({
            target: address(target),
            value: 0,
            callData: setValueOnTarget
        });
        executions[1] = Execution({
            target: target2,
            value: target2Amount,
            callData: ""
        });

        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );

        // Get the account, initcode and nonce
        (address account, bytes memory initCode) = getMEWAndInitCode();
        uint256 nonce = getNonce(account, address(ecdsaValidator));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(account);
        userOp.nonce = nonce;
        userOp.initCode = initCode;
        userOp.callData = userOpCalldata;

        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            owner1Key,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Send the userOp to the entrypoint
        entrypoint.handleOps(userOps, payable(address(0x69)));

        // Assert that the value was set ie that execution was successful
        assertTrue(target.value() == 1337);
        assertTrue(target2.balance == target2Amount);
    }

    function test_execSingleFromExecutor() public {
        address account = test_execSingleMEW();

        bytes[] memory ret = defaultExecutor.executeViaAccount(
            IERC7579Account(address(account)),
            address(target),
            0,
            abi.encodePacked(MockTarget.setValue.selector, uint256(1338))
        );

        assertEq(ret.length, 1);
        assertEq(abi.decode(ret[0], (uint256)), 1338);
    }

    function test_execBatchFromExecutor() public {
        address account = test_execSingleMEW();

        bytes memory setValueOnTarget = abi.encodeCall(
            MockTarget.setValue,
            1338
        );
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution({
            target: address(target),
            value: 0,
            callData: setValueOnTarget
        });
        executions[1] = Execution({
            target: address(target),
            value: 0,
            callData: setValueOnTarget
        });
        bytes[] memory ret = defaultExecutor.execBatch({
            account: IERC7579Account(address(account)),
            execs: executions
        });

        assertEq(ret.length, 2);
        assertEq(abi.decode(ret[0], (uint256)), 1338);
    }

    function test_execFromAnotherOwner() public {
        // Create calldata for the account to execute
        bytes memory setValueOnTarget = abi.encodeCall(
            MockTarget.setValue,
            1337
        );
        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(
                    address(target),
                    uint256(0),
                    setValueOnTarget
                )
            )
        );
        // Get the account and nonce
        mewAccount = setupMEW();
        uint256 nonce = getNonce(address(mewAccount), address(ecdsaValidator));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(mewAccount);
        userOp.nonce = nonce;
        userOp.callData = userOpCalldata;

        vm.prank(owner1);
        mewAccount.addOwner(owner2);

        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            owner2Key,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        entrypoint.handleOps(userOps, payable(address(0x69)));

        assertTrue(target.value() == 1337);
    }

    function test_fail_execFromNonOwner() public {
        // Create calldata for the account to execute
        bytes memory setValueOnTarget = abi.encodeCall(
            MockTarget.setValue,
            1337
        );
        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(
                    address(target),
                    uint256(0),
                    setValueOnTarget
                )
            )
        );
        // Get the account and nonce
        mewAccount = setupMEW();
        uint256 nonce = getNonce(address(mewAccount), address(ecdsaValidator));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(mewAccount);
        userOp.nonce = nonce;
        userOp.callData = userOpCalldata;

        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            badActorKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;
        PackedUserOperation[] memory badUserOps = new PackedUserOperation[](1);
        badUserOps[0] = userOp;

        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        entrypoint.handleOps(badUserOps, payable(address(0x69)));
    }

    // AccessController

    function test_pass_isOwner() public {
        mewAccount = setupMEW();
        assertTrue(mewAccount.isOwner(owner1));
    }

    function test_fail_isOwner() public {
        mewAccount = setupMEW();
        assertFalse(mewAccount.isOwner(badActor));
    }

    function test_pass_addOwner() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addOwner(owner2);
        assertTrue(mewAccount.isOwner(owner2));
        assertEq(2, mewAccount.ownerCount());
    }

    function test_emit_addOwner() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        vm.expectEmit(true, true, true, true);
        emit OwnerAdded(address(mewAccount), owner2);
        mewAccount.addOwner(owner2);
    }

    function test_fail_addOwner_OnlyOwnerOrSelf() public {
        mewAccount = setupMEW();
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrSelf.selector);
        mewAccount.addOwner(owner2);
    }

    function test_fail_addOwner_AddingInvalidOwner() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        vm.expectRevert(AddingInvalidOwner.selector);
        mewAccount.addOwner(address(0));
        vm.expectRevert(AddingInvalidOwner.selector);
        mewAccount.addOwner(owner1);
        mewAccount.addGuardian(guardian1);
        vm.expectRevert(AddingInvalidOwner.selector);
        mewAccount.addOwner(guardian1);
    }

    function test_pass_removeOwner() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addOwner(owner2);
        assertTrue(mewAccount.isOwner(owner2));
        mewAccount.removeOwner(owner1);
        assertFalse(mewAccount.isOwner(owner1));
        assertEq(1, mewAccount.ownerCount());
    }

    function test_emit_removeOwner() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addOwner(owner2);
        vm.expectEmit(true, true, true, true);
        emit OwnerRemoved(address(mewAccount), owner2);
        mewAccount.removeOwner(owner2);
    }

    function test_fail_removeOwner_OnlyOwnerOrSelf() public {
        mewAccount = setupMEW();
        vm.prank(owner1);
        mewAccount.addOwner(owner2);
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrSelf.selector);
        mewAccount.removeOwner(owner2);
    }

    function test_fail_removeOwner_RemovingInvalidOwner() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        vm.expectRevert(RemovingInvalidOwner.selector);
        mewAccount.removeOwner(address(0));
        vm.expectRevert(RemovingInvalidOwner.selector);
        mewAccount.removeOwner(owner2);
    }

    function test_fail_removeOwner_WalletNeedsOwner() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        vm.expectRevert(WalletNeedsOwner.selector);
        mewAccount.removeOwner(owner1);
    }

    function test_pass_isGuardian() public {
        mewAccount = setupMEW();
        vm.prank(owner1);
        mewAccount.addGuardian(guardian1);
        assertTrue(mewAccount.isGuardian(guardian1));
    }

    function test_fail_isGuardian() public {
        mewAccount = setupMEW();
        vm.prank(owner1);
        mewAccount.addGuardian(guardian1);
        assertFalse(mewAccount.isGuardian(badActor));
    }

    function test_pass_addGuardian() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(owner2);
        assertTrue(mewAccount.isGuardian(owner2));
        assertEq(1, mewAccount.guardianCount());
    }

    function test_emit_addGuardian() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        vm.expectEmit(true, true, true, true);
        emit GuardianAdded(address(mewAccount), guardian1);
        mewAccount.addGuardian(guardian1);
    }

    function test_fail_addGuardian_OnlyOwnerOrSelf() public {
        mewAccount = setupMEW();
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrSelf.selector);
        mewAccount.addGuardian(guardian1);
    }

    function test_fail_addGuardian_AddingInvalidGuardian() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        vm.expectRevert(AddingInvalidGuardian.selector);
        mewAccount.addGuardian(address(0));
        vm.expectRevert(AddingInvalidGuardian.selector);
        mewAccount.addGuardian(owner1);
        vm.expectRevert(AddingInvalidGuardian.selector);
        mewAccount.addGuardian(guardian1);
    }

    function test_pass_removeGuardian() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        assertTrue(mewAccount.isGuardian(guardian1));
        mewAccount.removeGuardian(guardian1);
        assertFalse(mewAccount.isGuardian(guardian1));
        assertEq(0, mewAccount.guardianCount());
    }

    function test_emit_removeGuardian() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        vm.expectEmit(true, true, true, true);
        emit GuardianRemoved(address(mewAccount), guardian1);
        mewAccount.removeGuardian(guardian1);
    }

    function test_fail_removeGuardian_OnlyOwnerOrSelf() public {
        mewAccount = setupMEW();
        vm.prank(owner1);
        mewAccount.addGuardian(guardian1);
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrSelf.selector);
        mewAccount.removeGuardian(guardian1);
    }

    function test_fail_removeGuardian_RemovingInvalidGuardian() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        vm.expectRevert(RemovingInvalidGuardian.selector);
        mewAccount.removeGuardian(address(0));
        vm.expectRevert(RemovingInvalidGuardian.selector);
        mewAccount.removeGuardian(badActor);
    }

    function test_pass_changeProposalTimelock() public {
        mewAccount = setupMEW();
        vm.prank(owner1);
        mewAccount.changeProposalTimelock(6 days);
        assertEq(6 days, mewAccount.proposalTimelock());
    }

    function test_emit_changeProposalTimelock() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        vm.expectEmit(true, true, true, true);
        emit ProposalTimelockChanged(address(mewAccount), 6 days);
        mewAccount.changeProposalTimelock(6 days);
    }

    function test_fail_changeProposalTimelock() public {
        mewAccount = setupMEW();
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrSelf.selector);
        mewAccount.changeProposalTimelock(6 days);
    }

    function test_pass_guardianPropose() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        mewAccount.guardianPropose(owner2);
        assertEq(1, mewAccount.proposalId());
    }

    function test_emit_guardianPropose() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        vm.expectEmit(true, true, true, true);
        emit ProposalSubmitted(address(mewAccount), 1, owner2, guardian1);
        mewAccount.guardianPropose(owner2);
    }

    function test_fail_guardianPropose_OnlyGuardian() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.expectRevert(OnlyGuardian.selector);
        mewAccount.guardianPropose(owner2);
    }

    function test_fail_guardianPropose_NotEnoughGuardians() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        vm.stopPrank();
        vm.prank(guardian1);
        vm.expectRevert(NotEnoughGuardians.selector);
        mewAccount.guardianPropose(owner2);
    }

    function test_fail_guardianPropose_AddingInvalidOwner() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        vm.expectRevert(AddingInvalidOwner.selector);
        mewAccount.guardianPropose(address(0));
        vm.expectRevert(AddingInvalidOwner.selector);
        mewAccount.guardianPropose(guardian1);
        vm.expectRevert(AddingInvalidOwner.selector);
        mewAccount.guardianPropose(owner1);
    }

    function test_fail_guardianPropose_ProposalUnresolved() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        mewAccount.guardianPropose(owner2);
        vm.expectRevert(ProposalUnresolved.selector);
        mewAccount.guardianPropose(owner2);
    }

    function test_pass_getProposal() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        mewAccount.guardianPropose(owner2);
        (
            address proposedNewOwner,
            uint256 approvalCount,
            address[] memory guardiansApproved,
            bool resolved,

        ) = mewAccount.getProposal(1);
        assertEq(owner2, proposedNewOwner);
        assertEq(1, approvalCount);
        assertEq(guardian1, guardiansApproved[0]);
        assertEq(false, resolved);
    }

    function test_fail_getProposal_InvalidProposal() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        vm.expectRevert(InvalidProposal.selector);
        mewAccount.getProposal(0);
        vm.expectRevert(InvalidProposal.selector);
        mewAccount.getProposal(1);
    }

    function test_passAndEmit_guardianCosign_QuorumNotReached() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        mewAccount.addGuardian(guardian4);
        vm.stopPrank();
        vm.prank(guardian1);
        mewAccount.guardianPropose(owner2);
        vm.prank(guardian2);
        vm.expectEmit(true, true, true, true);
        emit QuorumNotReached(address(mewAccount), 1, owner2, 2);
        mewAccount.guardianCosign();
    }

    function test_pass_guardianCosign_OwnerAdded() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        mewAccount.guardianPropose(owner2);
        vm.prank(guardian2);
        mewAccount.guardianCosign();
        assertTrue(mewAccount.isOwner(owner2));
    }

    function test_fail_guardianCosign_OnlyGuardian() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        mewAccount.guardianPropose(owner2);
        vm.prank(badActor);
        vm.expectRevert(OnlyGuardian.selector);
        mewAccount.guardianCosign();
    }

    function test_fail_guardianCosign_InvalidProposal() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        vm.expectRevert(InvalidProposal.selector);
        mewAccount.guardianCosign();
    }

    function test_fail_guardianCosign_AlreadySignedProposal() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        mewAccount.guardianPropose(owner2);
        vm.expectRevert(AlreadySignedProposal.selector);
        mewAccount.guardianCosign();
    }

    function test_fail_guardianCosign_ProposalResolved() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        mewAccount.guardianPropose(owner2);
        vm.prank(guardian2);
        mewAccount.guardianCosign();
        assertTrue(mewAccount.isOwner(owner2));
        vm.prank(guardian3);
        vm.expectRevert(ProposalResolved.selector);
        mewAccount.guardianCosign();
    }

    function test_pass_discardCurrentProposal() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        mewAccount.guardianPropose(owner2);
        bool resolved;
        (, , , resolved, ) = mewAccount.getProposal(1);
        assertFalse(resolved);
        vm.warp(25 hours);
        mewAccount.discardCurrentProposal();
        (, , , resolved, ) = mewAccount.getProposal(1);
        assertTrue(resolved);
        assertFalse(mewAccount.isOwner(owner2));
    }

    function test_emit_discardCurrentProposal() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        mewAccount.guardianPropose(owner2);
        bool resolved;
        (, , , resolved, ) = mewAccount.getProposal(1);
        assertFalse(resolved);
        vm.warp(25 hours);
        vm.expectEmit(true, true, true, true);
        emit ProposalDiscarded(address(mewAccount), 1, guardian1);

        mewAccount.discardCurrentProposal();
    }

    function test_fail_discardCurrentProposal_OnlyOwnerOrGuardianOrSelf()
        public
    {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        mewAccount.guardianPropose(owner2);
        vm.warp(25 hours);
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrGuardianOrSelf.selector);
        mewAccount.discardCurrentProposal();
    }

    function test_fail_discardCurrentProposal_ProposalResolved() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        mewAccount.guardianPropose(owner2);
        vm.startPrank(guardian2);
        mewAccount.guardianCosign();
        vm.expectRevert(ProposalResolved.selector);
        mewAccount.discardCurrentProposal();
    }

    function test_fail_discardCurrentProposal_ProposalTimelocked() public {
        mewAccount = setupMEW();
        vm.startPrank(owner1);
        mewAccount.addGuardian(guardian1);
        mewAccount.addGuardian(guardian2);
        mewAccount.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        mewAccount.guardianPropose(owner2);
        vm.expectRevert(ProposalTimelocked.selector);
        mewAccount.discardCurrentProposal();
    }
}
