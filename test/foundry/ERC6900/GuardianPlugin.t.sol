// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";

import {EntryPoint} from "@ERC4337/core/EntryPoint.sol";
import {UserOperation} from "@ERC4337/interfaces/UserOperation.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {MultipleOwnerPlugin} from "../../../src/ERC6900/plugins/MultipleOwnerPlugin.sol";
import {GuardianPlugin} from "../../../src/ERC6900/plugins/GuardianPlugin.sol";
import {EtherspotWalletV2} from "../../../src/ERC6900/wallet/EtherspotWalletV2.sol";
import {MSCAFactoryFixture} from "./MSCAFactoryFixture.sol";
import {IMultipleOwnerPlugin} from "../../../src/ERC6900/interfaces/IMultipleOwnerPlugin.sol";
import {IGuardianPlugin} from "../../../src/ERC6900/interfaces/IGuardianPlugin.sol";
import {ErrorsLib} from "../../../src/ERC6900/libraries/ErrorsLib.sol";

import {IPluginManager} from "@ERC6900/src/interfaces/IPluginManager.sol";
import {FunctionReference, FunctionReferenceLib} from "@ERC6900/src/libraries/FunctionReferenceLib.sol";

contract GuardianPluginTest is Test {
    using ECDSA for bytes32;
    using FunctionReferenceLib for address;

    EtherspotWalletV2 public account;
    MultipleOwnerPlugin public ownerPlugin;
    GuardianPlugin public guardianPlugin;
    EntryPoint public entryPoint;

    uint24 immutable INITIAL_PROPOSAL_TIMELOCK = 24 hours;
    address public a;
    address public b;

    address public owner1;
    uint256 public owner1Key;
    address public owner2;
    address public owner3;
    address public badOwner;
    address public guardian1;
    address public guardian2;
    address public guardian3;
    address public guardian4;
    address public badGuardian;

    struct NewOwnerProposal {
        address newOwnerProposed;
        bool resolved;
        uint256 approvalCount;
        address[] guardiansApproved;
        uint256 proposedAt;
    }

    struct AccountGuardianInformation {
        mapping(address => bool) guardians;
        uint256 guardianCount;
        uint256 currentProposalId;
        uint256 proposalTimelockApplied;
        mapping(uint256 => NewOwnerProposal) proposals;
    }

    // Event declarations (needed for vm.expectEmit)
    event GuardianAdded(address account, address guardianAdded);
    event GuardianProposalSubmitted(
        address account,
        uint256 proposalId,
        address newOwnerProposed
    );
    event QuorumNotReached(
        address account,
        uint256 proposalId,
        address newOwnerProposed,
        uint256 approvalCount
    );
    event ProposalDiscarded(address account, uint256 proposalId);

    // Error declarations (needed for vm.expectRevert)
    error GuardianCannotBeOwner();
    error AlreadyAGuardian();
    error InvalidGuardian();
    error NotAuthorized();
    error NotAGuardian();
    error InvalidTotalGuardians();
    error UnresolvedGuardianProposal();
    error NoValidProposal();
    error GuardianAlreadySignedProposal();
    error GuardianProposalResolved();
    error ProposalTimelockBound();

    function setUp() public {
        ownerPlugin = new MultipleOwnerPlugin();
        guardianPlugin = new GuardianPlugin();
        entryPoint = new EntryPoint();

        MSCAFactoryFixture factory = new MSCAFactoryFixture(
            entryPoint,
            ownerPlugin
        );

        a = makeAddr("a");
        b = makeAddr("b");
        (owner1, owner1Key) = makeAddrAndKey("owner1");
        owner2 = makeAddr("owner2");
        owner3 = makeAddr("owner3");
        badOwner = makeAddr("badOwner");
        guardian1 = makeAddr("guardian1");
        guardian2 = makeAddr("guardian2");
        guardian3 = makeAddr("guardian3");
        guardian4 = makeAddr("guardian4");
        badGuardian = makeAddr("badGuardian");

        account = factory.createAccount(owner1, 0);
        vm.startPrank(owner1);

        FunctionReference[]
            memory guardianDependencies = new FunctionReference[](1);
        guardianDependencies[0] = address(ownerPlugin).pack(
            uint8(
                IMultipleOwnerPlugin.FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF
            )
        );

        // Add the guardian plugin to the account
        bytes32 guardianPluginManifestHash = keccak256(
            abi.encode(guardianPlugin.pluginManifest())
        );

        account.installPlugin({
            plugin: address(guardianPlugin),
            manifestHash: guardianPluginManifestHash,
            pluginInitData: abi.encode(address(ownerPlugin)),
            dependencies: guardianDependencies,
            injectedHooks: new IPluginManager.InjectedHook[](0)
        });

        vm.stopPrank();
    }

    function test_uninitializedGuardian() public {
        vm.startPrank(a);
        assertEq(false, guardianPlugin.isGuardianOfAccount(a, guardian1));
    }

    function test_guardianInitialization() public {
        vm.startPrank(a);
        assertEq(false, guardianPlugin.isGuardianOfAccount(a, guardian1));
        guardianPlugin.addGuardian(guardian1);
        assertEq(true, guardianPlugin.isGuardianOfAccount(a, guardian1));
    }

    function test_requireOwnerOrGuardian() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.runtimeValidationFunction(
            uint8(IGuardianPlugin.FunctionId.RUNTIME_VALIDATION_GUARDIAN),
            guardian1,
            0,
            ""
        );
        ownerPlugin.transferOwnership(owner1);
        guardianPlugin.runtimeValidationFunction(
            uint8(
                IMultipleOwnerPlugin.FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF
            ),
            owner1,
            0,
            ""
        );
        vm.startPrank(b);
        vm.expectRevert(ErrorsLib.NotAuthorized.selector);
        guardianPlugin.runtimeValidationFunction(
            uint8(IGuardianPlugin.FunctionId.RUNTIME_VALIDATION_GUARDIAN),
            guardian1,
            0,
            ""
        );
        vm.expectRevert(ErrorsLib.NotAuthorized.selector);
        guardianPlugin.runtimeValidationFunction(
            uint8(
                IMultipleOwnerPlugin.FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF
            ),
            owner1,
            0,
            ""
        );
    }

    function test_failAddGuardian_InvalidGuardian() public {
        vm.startPrank(a);
        vm.expectRevert(InvalidGuardian.selector);
        guardianPlugin.addGuardian(address(0));
    }

    function test_failAddGuardian_GuardianCannotBeOwner() public {
        vm.startPrank(a);
        ownerPlugin.transferOwnership(guardian1);
        vm.expectRevert(GuardianCannotBeOwner.selector);
        guardianPlugin.addGuardian(guardian1);
    }

    function test_failAddGuardian_AlreadyAGuardian() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        vm.expectRevert(AlreadyAGuardian.selector);
        guardianPlugin.addGuardian(guardian1);
    }

    function test_passAddGuardian() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        assertEq(true, guardianPlugin.isGuardianOfAccount(a, guardian1));
    }

    function test_emitAddGuardian() public {
        vm.startPrank(a);
        vm.expectEmit(true, true, true, true);
        emit GuardianAdded(a, guardian1);
        guardianPlugin.addGuardian(guardian1);
    }

    function test_passIsGuardian() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        assertEq(true, guardianPlugin.isGuardian(guardian1));
        assertEq(false, guardianPlugin.isGuardian(guardian2));
    }

    function test_passIsGuardianOfAccount() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        assertEq(true, guardianPlugin.isGuardianOfAccount(a, guardian1));
        assertEq(false, guardianPlugin.isGuardianOfAccount(a, guardian2));
    }

    function test_passGetOwnersForAccount() public {
        // check first owner added
        ownerPlugin.transferOwnership(owner1);
        assertEq(
            owner1,
            GuardianPlugin(address(account)).getOwnersForAccount(
                address(account)
            )[0]
        );
        ownerPlugin.addOwner(address(account), owner2);
        // check both owners added
        assertEq(
            owner1,
            GuardianPlugin(address(account)).getOwnersForAccount(
                address(account)
            )[0]
        );
        assertEq(
            owner2,
            GuardianPlugin(address(account)).getOwnersForAccount(
                address(account)
            )[1]
        );
        // remove first owner and check second takes it place in owner array
        ownerPlugin.removeOwner(address(account), owner1);
        assertEq(
            owner2,
            GuardianPlugin(address(account)).getOwnersForAccount(
                address(account)
            )[0]
        );
    }

    function test_passGetAccountGuardianCount() public {
        vm.startPrank(a);
        assertEq(0, guardianPlugin.getAccountGuardianCount(a));
        guardianPlugin.addGuardian(guardian1);
        assertEq(1, guardianPlugin.getAccountGuardianCount(a));
    }

    function test_passGetAccountCurrentProposalId() public {
        vm.startPrank(a);
        assertEq(0, guardianPlugin.getAccountCurrentProposalId(a));
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        assertEq(1, guardianPlugin.getAccountCurrentProposalId(a));
    }

    function test_passGetAccountProposalTimelock() public {
        vm.startPrank(a);
        assertEq(
            INITIAL_PROPOSAL_TIMELOCK,
            guardianPlugin.getAccountProposalTimelock(a)
        );
    }

    function test_passChangeProposalTimelock() public {
        vm.startPrank(a);
        assertEq(
            INITIAL_PROPOSAL_TIMELOCK,
            guardianPlugin.getAccountProposalTimelock(a)
        );
        guardianPlugin.changeProposalTimelock(6 days);
        assertEq(6 days, guardianPlugin.getAccountProposalTimelock(a));
    }

    function test_passChangeProposalTimelockDefaultAgain() public {
        vm.startPrank(a);
        guardianPlugin.changeProposalTimelock(6 days);
        assertEq(6 days, guardianPlugin.getAccountProposalTimelock(a));
        guardianPlugin.changeProposalTimelock(0);
        assertEq(
            INITIAL_PROPOSAL_TIMELOCK,
            guardianPlugin.getAccountProposalTimelock(a)
        );
    }

    function test_passGuardianPropose() public {
        vm.startPrank(a);
        uint256 cpId = 0;
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        assertEq(cpId + 1, guardianPlugin.getAccountCurrentProposalId(a));
        (
            address newOwnerProposed,
            bool resolved,
            uint256 approvalCount,
            address[] memory guardiansApproved,
            uint256 proposedAt
        ) = guardianPlugin.getProposal(a, cpId);
        assertEq(owner2, newOwnerProposed);
        assertEq(false, resolved);
        assertEq(1, approvalCount);
        assertEq(guardian1, guardiansApproved[0]);
        assertEq(1, guardiansApproved.length);
        assertEq(1, proposedAt);
    }

    function test_emitGuardianPropose() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        vm.expectEmit(true, true, true, true);
        emit GuardianProposalSubmitted(a, 0, owner2);
        guardianPlugin.guardianPropose(a, owner2);
    }

    function test_failGuardianPropose_InvalidTotalGuardians() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        vm.startPrank(guardian1);
        vm.expectRevert(InvalidTotalGuardians.selector);
        guardianPlugin.guardianPropose(a, owner2);
    }

    function test_failGuardianPropose_UnresolvedGuardianProposal() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.expectRevert(UnresolvedGuardianProposal.selector);
        guardianPlugin.guardianPropose(a, owner3);
    }

    function test_passGuardianCosign() public {
        vm.startPrank(a);
        ownerPlugin.transferOwnership(owner1);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.startPrank(guardian2);
        guardianPlugin.guardianCosign(a);
        (
            ,
            ,
            uint256 approvalCount,
            address[] memory guardiansApproved,

        ) = guardianPlugin.getProposal(a, 0);
        assertEq(2, approvalCount);
        assertEq(guardian1, guardiansApproved[0]);
        assertEq(guardian2, guardiansApproved[1]);
    }

    function test_emitGuardianCosign_NewOwnerAdded() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.startPrank(guardian2);
        vm.expectEmit(true, true, true, true);
        emit IMultipleOwnerPlugin.OwnerAdded(a, owner2);
        guardianPlugin.guardianCosign(a);
    }

    function test_emitGuardianCosign_QuorumNotReached() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        guardianPlugin.addGuardian(guardian4);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.startPrank(guardian2);
        vm.expectEmit(true, true, true, true);
        emit QuorumNotReached(a, 0, owner2, 2);
        guardianPlugin.guardianCosign(a);
    }

    function test_failGuardianCosign_NoValidProposal() public {
        vm.startPrank(a);
        vm.expectRevert(NoValidProposal.selector);
        guardianPlugin.guardianCosign(a);
    }

    function test_failGuardianCosignGuardian_GuardianAlreadySignedProposal()
        public
    {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.expectRevert(GuardianAlreadySignedProposal.selector);
        guardianPlugin.guardianCosign(a);
    }

    function test_failGuardianCosignProposal_GuardianProposalResolved() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.startPrank(guardian2);
        guardianPlugin.guardianCosign(a);
        vm.startPrank(guardian3);
        vm.expectRevert(GuardianProposalResolved.selector);
        guardianPlugin.guardianCosign(a);
    }

    function test_passDiscardCurrentProposal() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.warp(25 hours);
        guardianPlugin.discardCurrentProposal(a);
        (
            ,
            bool resolved,
            uint256 approvalCount,
            address[] memory guardiansApproved,

        ) = guardianPlugin.getProposal(a, 0);
        assertEq(true, resolved);
        assertEq(1, approvalCount);
        assertEq(guardian1, guardiansApproved[0]);
    }

    function test_emitDiscardCurrentProposal() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.warp(25 hours);
        vm.expectEmit(true, true, true, true);
        emit ProposalDiscarded(a, 0);
        guardianPlugin.discardCurrentProposal(a);
    }

    function test_failDiscardCurrentProposal_GuardianProposalResolved() public {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.startPrank(guardian2);
        guardianPlugin.guardianCosign(a);
        vm.warp(25 hours);
        vm.expectRevert(GuardianProposalResolved.selector);
        guardianPlugin.discardCurrentProposal(a);
    }

    function test_failDiscardCurrentProposal_ProposalTimelockBound_Initial()
        public
    {
        vm.startPrank(a);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.expectRevert(ProposalTimelockBound.selector);
        guardianPlugin.discardCurrentProposal(a);
    }

    function test_failDiscardCurrentProposal_ProposalTimelockBound_Changed()
        public
    {
        vm.startPrank(a);
        guardianPlugin.changeProposalTimelock(1 hours);
        guardianPlugin.addGuardian(guardian1);
        guardianPlugin.addGuardian(guardian2);
        guardianPlugin.addGuardian(guardian3);
        vm.startPrank(guardian1);
        guardianPlugin.guardianPropose(a, owner2);
        vm.expectRevert(ProposalTimelockBound.selector);
        guardianPlugin.discardCurrentProposal(a);
    }

    function test_executeFromPluginAllowed() public {
        ownerPlugin.addOwner(address(account), owner2);
        address[] memory result = GuardianPlugin(address(account))
            .getOwnersForAccount(address(account));

        assertEq(result[0], owner1);
        assertEq(result[1], owner2);
    }

    function test_badOwner_addGuardian() public {
        vm.prank(badOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.RuntimeValidationFunctionReverted.selector,
                address(ownerPlugin),
                0,
                abi.encodePacked(ErrorsLib.NotAuthorized.selector)
            )
        );
        GuardianPlugin(address(account)).addGuardian(guardian1);
    }

    function test_badGuardian_addGuardian() public {
        vm.prank(badGuardian);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.RuntimeValidationFunctionReverted.selector,
                address(ownerPlugin),
                0,
                abi.encodePacked(ErrorsLib.NotAuthorized.selector)
            )
        );
        GuardianPlugin(address(account)).addGuardian(guardian1);
    }

    function test_badOwner_removeGuardian() public {
        vm.prank(owner1);
        GuardianPlugin(address(account)).addGuardian(guardian1);
        vm.prank(badOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.RuntimeValidationFunctionReverted.selector,
                address(ownerPlugin),
                0,
                abi.encodePacked(ErrorsLib.NotAuthorized.selector)
            )
        );
        GuardianPlugin(address(account)).removeGuardian(guardian1);
    }

    function test_badGuardian_guardianPropose() public {
        vm.prank(owner1);
        GuardianPlugin(address(account)).addGuardian(guardian1);
        vm.prank(badGuardian);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.RuntimeValidationFunctionReverted.selector,
                address(guardianPlugin),
                1,
                abi.encodePacked(ErrorsLib.NotAuthorized.selector)
            )
        );
        GuardianPlugin(address(account)).guardianPropose(
            address(account),
            owner2
        );
    }

    function test_badGuardian_guardianCosign() public {
        vm.startPrank(owner1);
        GuardianPlugin(address(account)).addGuardian(guardian1);
        GuardianPlugin(address(account)).addGuardian(guardian2);
        GuardianPlugin(address(account)).addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        GuardianPlugin(address(account)).guardianPropose(
            address(account),
            owner2
        );
        vm.prank(badGuardian);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.RuntimeValidationFunctionReverted.selector,
                address(guardianPlugin),
                1,
                abi.encodePacked(ErrorsLib.NotAuthorized.selector)
            )
        );
        GuardianPlugin(address(account)).guardianCosign(address(account));
    }

    function test_badGuardian_discardCurrentProposal() public {
        vm.startPrank(owner1);
        GuardianPlugin(address(account)).addGuardian(guardian1);
        GuardianPlugin(address(account)).addGuardian(guardian2);
        GuardianPlugin(address(account)).addGuardian(guardian3);
        vm.stopPrank();
        vm.prank(guardian1);
        GuardianPlugin(address(account)).guardianPropose(
            address(account),
            owner2
        );
        vm.prank(badGuardian);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.RuntimeValidationFunctionReverted.selector,
                address(guardianPlugin),
                0,
                abi.encodePacked(ErrorsLib.NotAuthorized.selector)
            )
        );
        GuardianPlugin(address(account)).discardCurrentProposal(
            address(account)
        );
    }

    function test_badPreviousOwner_discardCurrentProposal() public {
        vm.startPrank(owner1);
        GuardianPlugin(address(account)).addGuardian(guardian1);
        GuardianPlugin(address(account)).addGuardian(guardian2);
        GuardianPlugin(address(account)).addGuardian(guardian3);
        MultipleOwnerPlugin(address(account)).transferOwnership(owner2);
        vm.stopPrank();
        vm.prank(guardian1);
        GuardianPlugin(address(account)).guardianPropose(
            address(account),
            owner2
        );
        vm.prank(owner1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.RuntimeValidationFunctionReverted.selector,
                address(guardianPlugin),
                0,
                abi.encodePacked(ErrorsLib.NotAuthorized.selector)
            )
        );
        GuardianPlugin(address(account)).discardCurrentProposal(
            address(account)
        );
    }
}
