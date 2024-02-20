// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {MockValidator} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockValidator.sol";
import {MockExecutor} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockExecutor.sol";
import {MockTarget} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockTarget.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/Bootstrap.t.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";
import {IAccountConfig, IAccountConfig_Hook, IModularEtherspotWallet, IExecution} from "../../../src/modular-etherspot-wallet/interfaces/IModularEtherspotWallet.sol";
import {ModularEtherspotWallet} from "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {ModularEtherspotWalletFactory} from "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";
import {ECDSA, MultipleOwnerECDSAValidator} from "../../../src/modular-etherspot-wallet/modules/MultipleOwnerECDSAValidator.sol";

contract ModularEtherspotWalletTest is BootstrapUtil, Test {
    bytes32 immutable SALT = bytes32("TestSALT");

    // singletons
    ModularEtherspotWallet implementation;
    ModularEtherspotWalletFactory factory;
    IEntryPoint entrypoint = IEntryPoint(ENTRYPOINT_ADDR);
    MockValidator defaultValidator;
    MockExecutor defaultExecutor;
    MultipleOwnerECDSAValidator ecdsaValidator;
    MockTarget target;
    ModularEtherspotWallet account;

    uint256 nonce;
    address owner1;
    uint256 owner1Key;
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

    function setUp() public virtual {
        etchEntrypoint();
        implementation = new ModularEtherspotWallet();
        factory = new ModularEtherspotWalletFactory(address(implementation));

        // setup module singletons
        defaultExecutor = new MockExecutor();
        defaultValidator = new MockValidator();
        console2.log("default executor:", address(defaultExecutor));

        target = new MockTarget();
        ecdsaValidator = new MultipleOwnerECDSAValidator();
        console2.log("ecdsa validator:", address(ecdsaValidator));

        (owner1, owner1Key) = makeAddrAndKey("owner1");
        (owner2, owner2Key) = makeAddrAndKey("owner2");
        (guardian1, guardian1Key) = makeAddrAndKey("guardian1");
        (guardian2, guardian2Key) = makeAddrAndKey("guardian2");
        (guardian3, guardian3Key) = makeAddrAndKey("guardian3");
        (guardian4, guardian4Key) = makeAddrAndKey("guardian4");
        (badActor, badActorKey) = makeAddrAndKey("badActor");

        // setup account init config
        BootstrapConfig[] memory validators = makeBootstrapConfig(
            address(ecdsaValidator),
            abi.encodePacked(owner1)
        );
        BootstrapConfig[] memory executors = makeBootstrapConfig(
            address(defaultExecutor),
            ""
        );
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig memory fallbackHandler = _makeBootstrapConfig(
            address(0),
            ""
        );

        bytes memory initCode = abi.encode(
            owner1,
            address(bootstrapSingleton),
            abi.encodeCall(
                Bootstrap.initMSA,
                (validators, executors, hook, fallbackHandler)
            )
        );

        vm.startPrank(owner1);
        // create account
        account = ModularEtherspotWallet(
            payable(factory.createAccount({salt: SALT, initCode: initCode}))
        );
        console2.log("account address:", address(account));
        vm.deal(address(account), 1 ether);
        vm.stopPrank();
    }

    function test_AccountFeatureDetectionExecutors() public {
        assertTrue(
            account.supportsInterface(type(IModularEtherspotWallet).interfaceId)
        );
    }

    function test_AccountFeatureDetectionConfig() public {
        assertTrue(account.supportsInterface(type(IAccountConfig).interfaceId));
    }

    function test_AccountFeatureDetectionConfigWHooks() public {
        assertFalse(
            account.supportsInterface(type(IAccountConfig_Hook).interfaceId)
        );
    }

    function test_checkValidatorEnabled() public {
        assertTrue(account.isValidatorInstalled(address(ecdsaValidator)));
    }

    function test_checkExecutorEnabled() public {
        assertTrue(account.isExecutorInstalled(address(defaultExecutor)));
    }

    function test_execVia4337() public {
        bytes memory setValueOnTarget = abi.encodeCall(
            MockTarget.setValue,
            1337
        );
        bytes memory execFunction = abi.encodeCall(
            IExecution.execute,
            (address(target), 0, setValueOnTarget)
        );

        (address owner, uint256 ownerKey) = makeAddrAndKey("owner");

        bytes memory initCode = abi.encode(
            owner,
            address(bootstrapSingleton),
            abi.encodeCall(
                Bootstrap.singleInitMSA,
                (ecdsaValidator, abi.encodePacked(owner))
            )
        );

        address newAccount = factory.getAddress(SALT, initCode);
        vm.deal(newAccount, 1 ether);

        uint192 key = uint192(bytes24(bytes20(address(ecdsaValidator))));
        nonce = entrypoint.getNonce(address(account), key);

        UserOperation memory userOp = UserOperation({
            sender: newAccount,
            nonce: nonce,
            initCode: abi.encodePacked(
                address(factory),
                abi.encodeWithSelector(
                    factory.createAccount.selector,
                    SALT,
                    initCode
                )
            ),
            callData: execFunction,
            callGasLimit: 2e6,
            verificationGasLimit: 2e6,
            preVerificationGas: 2e6,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: ""
        });

        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entrypoint.handleOps(userOps, payable(address(0x69)));

        assertTrue(target.value() == 1337);
    }

    function test_execFromAnotherOwner() public {
        bytes memory setValueOnTarget = abi.encodeCall(
            MockTarget.setValue,
            1337
        );
        bytes memory execFunction = abi.encodeCall(
            IExecution.execute,
            (address(target), 0, setValueOnTarget)
        );

        uint192 key = uint192(bytes24(bytes20(address(ecdsaValidator))));
        nonce = entrypoint.getNonce(address(account), key);

        UserOperation memory userOp = UserOperation({
            sender: address(account),
            nonce: nonce,
            initCode: "",
            callData: execFunction,
            callGasLimit: 2e6,
            verificationGasLimit: 2e6,
            preVerificationGas: 2e6,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: ""
        });

        vm.prank(owner1);
        account.addOwner(owner2);

        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            owner2Key,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entrypoint.handleOps(userOps, payable(address(0x69)));

        assertTrue(target.value() == 1337);
    }

    function test_fail_execFromNonOwner() public {
        /// should fail using non-owner for same UserOp
        bytes memory setValueOnTarget = abi.encodeCall(
            MockTarget.setValue,
            1337
        );
        bytes memory execFunction = abi.encodeCall(
            IExecution.execute,
            (address(target), 0, setValueOnTarget)
        );

        uint192 key = uint192(bytes24(bytes20(address(ecdsaValidator))));
        nonce = entrypoint.getNonce(address(account), key);

        UserOperation memory userOp = UserOperation({
            sender: address(account),
            nonce: nonce,
            initCode: "",
            callData: execFunction,
            callGasLimit: 2e6,
            verificationGasLimit: 2e6,
            preVerificationGas: 2e6,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: ""
        });

        nonce = entrypoint.getNonce(address(account), key);
        userOp.nonce = nonce;

        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            badActorKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;
        UserOperation[] memory badUserOps = new UserOperation[](1);
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
        assertTrue(account.isOwner(owner1));
    }

    function test_fail_isOwner() public {
        assertFalse(account.isOwner(badActor));
    }

    function test_pass_addOwner() public {
        vm.startPrank(owner1);
        account.addOwner(owner2);
        assertTrue(account.isOwner(owner2));
        assertEq(2, account.ownerCount());
    }

    function test_emit_addOwner() public {
        vm.startPrank(owner1);
        vm.expectEmit(true, true, true, true);
        emit OwnerAdded(address(account), owner2);
        account.addOwner(owner2);
    }

    function test_fail_addOwner_OnlyOwnerOrSelf() public {
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrSelf.selector);
        account.addOwner(owner2);
    }

    function test_fail_addOwner_AddingInvalidOwner() public {
        vm.startPrank(owner1);
        vm.expectRevert(AddingInvalidOwner.selector);
        account.addOwner(address(0));
        vm.expectRevert(AddingInvalidOwner.selector);
        account.addOwner(owner1);
        account.addGuardian(guardian1);
        vm.expectRevert(AddingInvalidOwner.selector);
        account.addOwner(guardian1);
    }

    function test_pass_removeOwner() public {
        vm.startPrank(owner1);
        account.addOwner(owner2);
        assertTrue(account.isOwner(owner2));
        account.removeOwner(owner1);
        assertFalse(account.isOwner(owner1));
        assertEq(1, account.ownerCount());
    }

    function test_emit_removeOwner() public {
        vm.startPrank(owner1);
        account.addOwner(owner2);
        vm.expectEmit(true, true, true, true);
        emit OwnerRemoved(address(account), owner2);
        account.removeOwner(owner2);
    }

    function test_fail_removeOwner_OnlyOwnerOrSelf() public {
        vm.prank(owner1);
        account.addOwner(owner2);
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrSelf.selector);
        account.removeOwner(owner2);
    }

    function test_fail_removeOwner_RemovingInvalidOwner() public {
        vm.startPrank(owner1);
        vm.expectRevert(RemovingInvalidOwner.selector);
        account.removeOwner(address(0));
        vm.expectRevert(RemovingInvalidOwner.selector);
        account.removeOwner(owner2);
    }

    function test_fail_removeOwner_WalletNeedsOwner() public {
        vm.startPrank(owner1);
        vm.expectRevert(WalletNeedsOwner.selector);
        account.removeOwner(owner1);
    }

    function test_pass_isGuardian() public {
        vm.prank(owner1);
        account.addGuardian(guardian1);
        assertTrue(account.isGuardian(guardian1));
    }

    function test_fail_isGuardian() public {
        vm.prank(owner1);
        account.addGuardian(guardian1);
        assertFalse(account.isGuardian(badActor));
    }

    function test_pass_addGuardian() public {
        vm.startPrank(owner1);
        account.addGuardian(owner2);
        assertTrue(account.isGuardian(owner2));
        assertEq(1, account.guardianCount());
    }

    function test_emit_addGuardian() public {
        vm.startPrank(owner1);
        vm.expectEmit(true, true, true, true);
        emit GuardianAdded(address(account), guardian1);
        account.addGuardian(guardian1);
    }

    function test_fail_addGuardian_OnlyOwnerOrSelf() public {
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrSelf.selector);
        account.addGuardian(guardian1);
    }

    function test_fail_addGuardian_AddingInvalidGuardian() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        vm.expectRevert(AddingInvalidGuardian.selector);
        account.addGuardian(address(0));
        vm.expectRevert(AddingInvalidGuardian.selector);
        account.addGuardian(owner1);
        vm.expectRevert(AddingInvalidGuardian.selector);
        account.addGuardian(guardian1);
    }

    function test_pass_removeGuardian() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        assertTrue(account.isGuardian(guardian1));
        account.removeGuardian(guardian1);
        assertFalse(account.isGuardian(guardian1));
        assertEq(0, account.guardianCount());
    }

    function test_emit_removeGuardian() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        vm.expectEmit(true, true, true, true);
        emit GuardianRemoved(address(account), guardian1);
        account.removeGuardian(guardian1);
    }

    function test_fail_removeGuardian_OnlyOwnerOrSelf() public {
        vm.prank(owner1);
        account.addGuardian(guardian1);
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrSelf.selector);
        account.removeGuardian(guardian1);
    }

    function test_fail_removeGuardian_RemovingInvalidGuardian() public {
        vm.startPrank(owner1);
        vm.expectRevert(RemovingInvalidGuardian.selector);
        account.removeGuardian(address(0));
        vm.expectRevert(RemovingInvalidGuardian.selector);
        account.removeGuardian(badActor);
    }

    function test_pass_changeProposalTimelock() public {
        vm.prank(owner1);
        account.changeProposalTimelock(6 days);
        assertEq(6 days, account.proposalTimelock());
    }

    function test_emit_changeProposalTimelock() public {
        vm.startPrank(owner1);
        vm.expectEmit(true, true, true, true);
        emit ProposalTimelockChanged(address(account), 6 days);
        account.changeProposalTimelock(6 days);
    }

    function test_fail_changeProposalTimelock() public {
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrSelf.selector);
        account.changeProposalTimelock(6 days);
    }

    function test_pass_guardianPropose() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        account.guardianPropose(owner2);
        assertEq(1, account.proposalId());
    }

    function test_emit_guardianPropose() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        vm.expectEmit(true, true, true, true);
        emit ProposalSubmitted(address(account), 1, owner2, guardian1);
        account.guardianPropose(owner2);
    }

    function test_fail_guardianPropose_OnlyGuardian() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.expectRevert(OnlyGuardian.selector);
        account.guardianPropose(owner2);
    }

    function test_fail_guardianPropose_NotEnoughGuardians() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        vm.stopPrank();
        vm.prank(guardian1);
        vm.expectRevert(NotEnoughGuardians.selector);
        account.guardianPropose(owner2);
    }

    function test_fail_guardianPropose_AddingInvalidOwner() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        vm.expectRevert(AddingInvalidOwner.selector);
        account.guardianPropose(address(0));
        vm.expectRevert(AddingInvalidOwner.selector);
        account.guardianPropose(guardian1);
        vm.expectRevert(AddingInvalidOwner.selector);
        account.guardianPropose(owner1);
    }

    function test_fail_guardianPropose_ProposalUnresolved() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        account.guardianPropose(owner2);
        vm.expectRevert(ProposalUnresolved.selector);
        account.guardianPropose(owner2);
    }

    function test_pass_getProposal() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        account.guardianPropose(owner2);
        (
            address proposedNewOwner,
            uint256 approvalCount,
            address[] memory guardiansApproved,
            bool resolved,

        ) = account.getProposal(1);
        assertEq(owner2, proposedNewOwner);
        assertEq(1, approvalCount);
        assertEq(guardian1, guardiansApproved[0]);
        assertEq(false, resolved);
    }

    function test_fail_getProposal_InvalidProposal() public {
        vm.startPrank(owner1);
        vm.expectRevert(InvalidProposal.selector);
        account.getProposal(0);
        vm.expectRevert(InvalidProposal.selector);
        account.getProposal(1);
    }

    function test_passAndEmit_guardianCosign_QuorumNotReached() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        account.addGuardian(guardian4);
        vm.stopPrank();
        vm.prank(guardian1);
        account.guardianPropose(owner2);
        vm.prank(guardian2);
        vm.expectEmit(true, true, true, true);
        emit QuorumNotReached(address(account), 1, owner2, 2);
        account.guardianCosign();
    }

    function test_pass_guardianCosign_OwnerAdded() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        account.guardianPropose(owner2);
        vm.prank(guardian2);
        account.guardianCosign();
        assertTrue(account.isOwner(owner2));
    }

    function test_fail_guardianCosign_OnlyGuardian() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        account.guardianPropose(owner2);
        vm.prank(badActor);
        vm.expectRevert(OnlyGuardian.selector);
        account.guardianCosign();
    }

    function test_fail_guardianCosign_InvalidProposal() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        vm.expectRevert(InvalidProposal.selector);
        account.guardianCosign();
    }

    function test_fail_guardianCosign_AlreadySignedProposal() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        account.guardianPropose(owner2);
        vm.expectRevert(AlreadySignedProposal.selector);
        account.guardianCosign();
    }

    function test_fail_guardianCosign_ProposalResolved() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        account.guardianPropose(owner2);
        vm.prank(guardian2);
        account.guardianCosign();
        assertTrue(account.isOwner(owner2));
        vm.prank(guardian3);
        vm.expectRevert(ProposalResolved.selector);
        account.guardianCosign();
    }

    function test_pass_discardCurrentProposal() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        account.guardianPropose(owner2);
        bool resolved;
        (, , , resolved, ) = account.getProposal(1);
        assertFalse(resolved);
        vm.warp(25 hours);
        account.discardCurrentProposal();
        (, , , resolved, ) = account.getProposal(1);
        assertTrue(resolved);
        assertFalse(account.isOwner(owner2));
    }

    function test_emit_discardCurrentProposal() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        account.guardianPropose(owner2);
        bool resolved;
        (, , , resolved, ) = account.getProposal(1);
        assertFalse(resolved);
        vm.warp(25 hours);
        vm.expectEmit(true, true, true, true);
        emit ProposalDiscarded(address(account), 1, guardian1);

        account.discardCurrentProposal();
    }

    function test_fail_discardCurrentProposal_OnlyOwnerOrGuardianOrSelf()
        public
    {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        account.guardianPropose(owner2);
        vm.warp(25 hours);
        vm.prank(badActor);
        vm.expectRevert(OnlyOwnerOrGuardianOrSelf.selector);
        account.discardCurrentProposal();
    }

    function test_fail_discardCurrentProposal_ProposalResolved() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        account.guardianPropose(owner2);
        vm.startPrank(guardian2);
        account.guardianCosign();
        vm.expectRevert(ProposalResolved.selector);
        account.discardCurrentProposal();
    }

    function test_fail_discardCurrentProposal_ProposalTimelocked() public {
        vm.startPrank(owner1);
        account.addGuardian(guardian1);
        account.addGuardian(guardian2);
        account.addGuardian(guardian3);
        vm.stopPrank();
        vm.startPrank(guardian1);
        account.guardianPropose(owner2);
        vm.expectRevert(ProposalTimelocked.selector);
        account.discardCurrentProposal();
    }
}
