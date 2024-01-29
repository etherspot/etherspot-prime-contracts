// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {UserOperation} from "@ERC4337/interfaces/UserOperation.sol";

import {EtherspotWalletV2, UUPSUpgradeable} from "../wallet/EtherspotWalletV2.sol";
import {ArrayLib} from "../libraries/ArrayLib.sol";
import {ErrorsLib} from "../libraries/ErrorsLib.sol";
import {IMultipleOwnerPlugin} from "../interfaces/IMultipleOwnerPlugin.sol";
import {IGuardianPlugin} from "../interfaces/IGuardianPlugin.sol";

import {ManifestFunction, ManifestAssociatedFunctionType, ManifestAssociatedFunction, PluginManifest, ManifestExecutionFunction} from "@ERC6900/src/interfaces/IPlugin.sol";
import {IStandardExecutor} from "@ERC6900/src/interfaces/IStandardExecutor.sol";
import {BasePlugin} from "@ERC6900/src/plugins/BasePlugin.sol";
import {IPluginExecutor} from "@ERC6900/src/interfaces/IPluginExecutor.sol";

contract GuardianPlugin is BasePlugin, IGuardianPlugin {
    IMultipleOwnerPlugin public multiOwnerPlugin;

    string public constant NAME = "Guardian Plugin";
    string public constant VERSION = "1.0.0";
    string public constant AUTHOR = "Etherspot";

    uint256 internal constant _SIG_VALIDATION_PASSED = 0;
    uint256 internal constant _SIG_VALIDATION_FAILED = 1;

    uint128 immutable MULTIPLY_FACTOR = 1000;
    uint16 immutable SIXTY_PERCENT = 600;
    uint24 immutable INITIAL_PROPOSAL_TIMELOCK = 24 hours;

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

    mapping(address => AccountGuardianInformation)
        internal _accountGuardianInfo;

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Execution functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    // @inheritdoc IGuardianPlugin
    function addGuardian(address _newGuardian) external {
        if (isGuardian(_newGuardian)) revert ErrorsLib.AlreadyAGuardian();
        _addGuardian(_newGuardian);
    }

    // @inheritdoc IGuardianPlugin
    function removeGuardian(address _guardian) external {
        if (!isGuardian(_guardian)) revert ErrorsLib.NotAGuardian();
        _removeGuardian(_guardian);
    }

    // @inheritdoc IGuardianPlugin
    function changeProposalTimelock(uint256 _newTimelock) external {
        _accountGuardianInfo[msg.sender].proposalTimelockApplied = _newTimelock;
        emit ProposalTimelockChanged(msg.sender, _newTimelock);
    }

    // @inheritdoc IGuardianPlugin
    function discardCurrentProposal(address _account) external {
        AccountGuardianInformation storage agInfo = _accountGuardianInfo[
            _account
        ];
        uint256 id;
        if (agInfo.currentProposalId != 0) id = agInfo.currentProposalId - 1;
        if (agInfo.proposals[id].resolved)
            revert ErrorsLib.GuardianProposalResolved();
        if (
            isGuardianOfAccount(_account, msg.sender) &&
            agInfo.proposalTimelockApplied > 0
        ) {
            if (
                (agInfo.proposals[id].proposedAt +
                    agInfo.proposalTimelockApplied) >= block.timestamp
            ) revert ErrorsLib.ProposalTimelockBound();
        }
        if (
            isGuardianOfAccount(_account, msg.sender) &&
            agInfo.proposalTimelockApplied == 0
        ) {
            if (
                (agInfo.proposals[id].proposedAt + INITIAL_PROPOSAL_TIMELOCK) >=
                block.timestamp
            ) {
                revert ErrorsLib.ProposalTimelockBound();
            }
        }
        agInfo.proposals[id].resolved = true;
        emit ProposalDiscarded(_account, id);
    }

    // @inheritdoc IGuardianPlugin
    function guardianPropose(address _account, address _newOwner) external {
        AccountGuardianInformation storage agInfo = _accountGuardianInfo[
            _account
        ];
        uint256 cpId = agInfo.currentProposalId;
        if (agInfo.guardianCount < 3) revert ErrorsLib.InvalidTotalGuardians();
        if (
            agInfo.currentProposalId != 0 &&
            agInfo.proposals[cpId - 1].guardiansApproved.length != 0 &&
            agInfo.proposals[cpId - 1].resolved == false
        ) revert ErrorsLib.UnresolvedGuardianProposal();
        agInfo.currentProposalId = cpId + 1;
        agInfo.proposals[cpId].newOwnerProposed = _newOwner;
        agInfo.proposals[cpId].resolved = false;
        agInfo.proposals[cpId].guardiansApproved.push(msg.sender);
        agInfo.proposals[cpId].approvalCount += 1;
        agInfo.proposals[cpId].proposedAt = block.timestamp;
        emit GuardianProposalSubmitted(_account, cpId, _newOwner);
    }

    // @inheritdoc IGuardianPlugin
    function guardianCosign(address _account) external {
        AccountGuardianInformation storage agInfo = _accountGuardianInfo[
            _account
        ];
        uint256 id;
        if (agInfo.currentProposalId != 0) id = agInfo.currentProposalId - 1;
        if (agInfo.proposals[id].approvalCount == 0)
            revert ErrorsLib.NoValidProposal();
        if (_checkIfSigned(_account, msg.sender, id))
            revert ErrorsLib.GuardianAlreadySignedProposal();
        if (agInfo.proposals[id].resolved)
            revert ErrorsLib.GuardianProposalResolved();
        agInfo.proposals[id].guardiansApproved.push(msg.sender);
        agInfo.proposals[id].approvalCount += 1;
        address newOwner = agInfo.proposals[id].newOwnerProposed;
        if (_checkQuorumReached(_account, id)) {
            agInfo.proposals[id].resolved = true;
            IMultipleOwnerPlugin(address(multiOwnerPlugin)).addOwner(
                _account,
                newOwner
            );
        } else {
            emit QuorumNotReached(
                _account,
                id,
                newOwner,
                agInfo.proposals[id].approvalCount
            );
        }
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Plugin view functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    // @inheritdoc IGuardianPlugin
    function isGuardian(address _guardian) public view returns (bool) {
        return _accountGuardianInfo[msg.sender].guardians[_guardian];
    }

    // @inheritdoc IGuardianPlugin
    function isGuardianOfAccount(
        address _account,
        address _guardian
    ) public view returns (bool) {
        return _accountGuardianInfo[_account].guardians[_guardian];
    }

    // @inheritdoc IGuardianPlugin
    function getOwnersForAccount(
        address _account
    ) public returns (address[] memory) {
        bytes memory returnData = IPluginExecutor(msg.sender).executeFromPlugin(
            abi.encodeCall(IMultipleOwnerPlugin.ownersOf, (_account))
        );
        return abi.decode(returnData, (address[]));
    }

    // @inheritdoc IGuardianPlugin
    function getProposal(
        address _account,
        uint256 _proposalId
    )
        public
        view
        returns (
            address newOwnerProposed,
            bool resolved,
            uint256 approvalCount,
            address[] memory guardiansApproved,
            uint256 proposedAt
        )
    {
        uint256 proposalId = _accountGuardianInfo[_account].currentProposalId;
        if (proposalId == 0 && _proposalId > proposalId)
            revert ErrorsLib.InvalidGuardianProposalId();
        NewOwnerProposal memory proposal = _accountGuardianInfo[_account]
            .proposals[_proposalId];
        return (
            proposal.newOwnerProposed,
            proposal.resolved,
            proposal.approvalCount,
            proposal.guardiansApproved,
            proposal.proposedAt
        );
    }

    // @inheritdoc IGuardianPlugin
    function getAccountGuardianCount(
        address _account
    ) external view returns (uint256) {
        return _accountGuardianInfo[_account].guardianCount;
    }

    // @inheritdoc IGuardianPlugin
    function getAccountCurrentProposalId(
        address _account
    ) external view returns (uint256) {
        return _accountGuardianInfo[_account].currentProposalId;
    }

    // @inheritdoc IGuardianPlugin
    function getAccountProposalTimelock(
        address _account
    ) external view returns (uint256) {
        uint256 timelock = _accountGuardianInfo[_account]
            .proposalTimelockApplied;
        if (timelock == 0) return INITIAL_PROPOSAL_TIMELOCK;
        return timelock;
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Plugin interface functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    /// @inheritdoc BasePlugin
    function onInstall(bytes calldata data) external override {
        address moPlugin = abi.decode(data, (address));
        multiOwnerPlugin = IMultipleOwnerPlugin(moPlugin);
    }

    /// @inheritdoc BasePlugin
    function onUninstall(bytes calldata) external override {
        delete _accountGuardianInfo[msg.sender];
    }

    /// @inheritdoc BasePlugin
    function runtimeValidationFunction(
        uint8 functionId,
        address sender,
        uint256,
        bytes calldata
    ) external view override {
        if (functionId == uint8(FunctionId.RUNTIME_VALIDATION_GUARDIAN)) {
            if (!isGuardianOfAccount(msg.sender, sender)) {
                revert ErrorsLib.NotAuthorized();
            }
            return;
        } else if (
            functionId ==
            uint8(FunctionId.RUNTIME_VALIDATION_OWNER_OR_GUARDIAN_OR_SELF)
        ) {
            if (
                !IMultipleOwnerPlugin(address(multiOwnerPlugin))
                    .isOwnerOfAccount(msg.sender, sender) &&
                !isGuardianOfAccount(msg.sender, sender) &&
                sender != msg.sender
            ) {
                revert ErrorsLib.NotAuthorized();
            }
            return;
        }
        revert NotImplemented();
    }

    /// @inheritdoc BasePlugin
    function pluginManifest()
        external
        pure
        override
        returns (PluginManifest memory)
    {
        PluginManifest memory manifest;

        manifest.name = NAME;
        manifest.version = VERSION;
        manifest.author = AUTHOR;

        manifest.executionFunctions = new ManifestExecutionFunction[](13);
        manifest.executionFunctions[0] = ManifestExecutionFunction(
            this.isGuardian.selector,
            new string[](0)
        );
        manifest.executionFunctions[1] = ManifestExecutionFunction(
            this.isGuardianOfAccount.selector,
            new string[](0)
        );
        manifest.executionFunctions[2] = ManifestExecutionFunction(
            this.getOwnersForAccount.selector,
            new string[](0)
        );
        manifest.executionFunctions[3] = ManifestExecutionFunction(
            this.getProposal.selector,
            new string[](0)
        );
        manifest.executionFunctions[4] = ManifestExecutionFunction(
            this.getAccountGuardianCount.selector,
            new string[](0)
        );
        manifest.executionFunctions[5] = ManifestExecutionFunction(
            this.getAccountCurrentProposalId.selector,
            new string[](0)
        );
        manifest.executionFunctions[6] = ManifestExecutionFunction(
            this.getAccountProposalTimelock.selector,
            new string[](0)
        );
        manifest.executionFunctions[7] = ManifestExecutionFunction(
            this.guardianPropose.selector,
            new string[](0)
        );
        manifest.executionFunctions[8] = ManifestExecutionFunction(
            this.guardianCosign.selector,
            new string[](0)
        );
        manifest.executionFunctions[9] = ManifestExecutionFunction(
            this.discardCurrentProposal.selector,
            new string[](0)
        );
        manifest.executionFunctions[10] = ManifestExecutionFunction(
            this.addGuardian.selector,
            new string[](0)
        );
        manifest.executionFunctions[11] = ManifestExecutionFunction(
            this.removeGuardian.selector,
            new string[](0)
        );
        manifest.executionFunctions[12] = ManifestExecutionFunction(
            this.changeProposalTimelock.selector,
            new string[](0)
        );

        ManifestFunction
            memory guardianRuntimeValidationFunction = ManifestFunction({
                functionType: ManifestAssociatedFunctionType.SELF,
                functionId: uint8(FunctionId.RUNTIME_VALIDATION_GUARDIAN),
                dependencyIndex: 0 // Unused.
            });
        ManifestFunction
            memory ownerOrSelfRuntimeValidationFunction = ManifestFunction({
                functionType: ManifestAssociatedFunctionType.DEPENDENCY,
                functionId: 0,
                dependencyIndex: 0 // First index position.
            });
        ManifestFunction
            memory ownerOrGuardianOrSelfRuntimeValidationFunction = ManifestFunction({
                functionType: ManifestAssociatedFunctionType.SELF,
                functionId: uint8(
                    FunctionId.RUNTIME_VALIDATION_OWNER_OR_GUARDIAN_OR_SELF
                ),
                dependencyIndex: 0 // Unused.
            });
        ManifestFunction memory alwaysAllowFunction = ManifestFunction({
            functionType: ManifestAssociatedFunctionType
                .RUNTIME_VALIDATION_ALWAYS_ALLOW,
            functionId: 0, // Unused.
            dependencyIndex: 0 // Unused.
        });
        manifest.runtimeValidationFunctions = new ManifestAssociatedFunction[](
            13
        );
        manifest.runtimeValidationFunctions[0] = ManifestAssociatedFunction({
            executionSelector: this.isGuardian.selector,
            associatedFunction: alwaysAllowFunction
        });
        manifest.runtimeValidationFunctions[1] = ManifestAssociatedFunction({
            executionSelector: this.isGuardianOfAccount.selector,
            associatedFunction: alwaysAllowFunction
        });
        manifest.runtimeValidationFunctions[2] = ManifestAssociatedFunction({
            executionSelector: this.getOwnersForAccount.selector,
            associatedFunction: alwaysAllowFunction
        });
        manifest.runtimeValidationFunctions[3] = ManifestAssociatedFunction({
            executionSelector: this.getProposal.selector,
            associatedFunction: alwaysAllowFunction
        });
        manifest.runtimeValidationFunctions[4] = ManifestAssociatedFunction({
            executionSelector: this.getAccountGuardianCount.selector,
            associatedFunction: alwaysAllowFunction
        });
        manifest.runtimeValidationFunctions[5] = ManifestAssociatedFunction({
            executionSelector: this.getAccountCurrentProposalId.selector,
            associatedFunction: alwaysAllowFunction
        });
        manifest.runtimeValidationFunctions[6] = ManifestAssociatedFunction({
            executionSelector: this.getAccountProposalTimelock.selector,
            associatedFunction: alwaysAllowFunction
        });
        manifest.runtimeValidationFunctions[7] = ManifestAssociatedFunction({
            executionSelector: this.addGuardian.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[8] = ManifestAssociatedFunction({
            executionSelector: this.removeGuardian.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[9] = ManifestAssociatedFunction({
            executionSelector: this.changeProposalTimelock.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[10] = ManifestAssociatedFunction({
            executionSelector: this.guardianPropose.selector,
            associatedFunction: guardianRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[11] = ManifestAssociatedFunction({
            executionSelector: this.guardianCosign.selector,
            associatedFunction: guardianRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[12] = ManifestAssociatedFunction({
            executionSelector: this.discardCurrentProposal.selector,
            associatedFunction: ownerOrGuardianOrSelfRuntimeValidationFunction
        });

        manifest.permittedExecutionSelectors = new bytes4[](1);
        manifest.permittedExecutionSelectors[0] = IMultipleOwnerPlugin
            .ownersOf
            .selector;

        manifest.dependencyInterfaceIds = new bytes4[](1);
        manifest.dependencyInterfaceIds[0] = type(IMultipleOwnerPlugin)
            .interfaceId;

        return manifest;
    }

    // ┏━━━━━━━━━━━━━━━┓
    // ┃    EIP-165    ┃
    // ┗━━━━━━━━━━━━━━━┛

    /// @inheritdoc BasePlugin
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == type(IGuardianPlugin).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Internal / Private functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    function _addGuardian(address _newGuardian) internal {
        AccountGuardianInformation storage agInfo = _accountGuardianInfo[
            msg.sender
        ];
        if (_newGuardian == address(0)) revert ErrorsLib.InvalidGuardian();
        if (isGuardian(_newGuardian)) revert ErrorsLib.AlreadyAGuardian();

        bool isOwner = IMultipleOwnerPlugin(address(multiOwnerPlugin))
            .isOwnerOfAccount(msg.sender, _newGuardian);

        if (isOwner) revert ErrorsLib.GuardianCannotBeOwner();
        emit GuardianAdded(msg.sender, _newGuardian);
        agInfo.guardians[_newGuardian] = true;
        agInfo.guardianCount = agInfo.guardianCount + 1;
    }

    function _removeGuardian(address _guardian) internal {
        AccountGuardianInformation storage agInfo = _accountGuardianInfo[
            msg.sender
        ];
        if (!isGuardian(_guardian)) revert ErrorsLib.NotAGuardian();
        emit GuardianRemoved(msg.sender, _guardian);
        agInfo.guardians[_guardian] = false;
        agInfo.guardianCount = agInfo.guardianCount - 1;
    }

    function _checkIfSigned(
        address _account,
        address _guardian,
        uint256 _proposalId
    ) internal view returns (bool) {
        AccountGuardianInformation storage agInfo = _accountGuardianInfo[
            _account
        ];
        if (
            !ArrayLib._contains(
                agInfo.proposals[_proposalId].guardiansApproved,
                _guardian
            )
        ) {
            return false;
        }
        return true;
    }

    function _checkQuorumReached(
        address _account,
        uint256 _proposalId
    ) internal view returns (bool) {
        AccountGuardianInformation storage agInfo = _accountGuardianInfo[
            _account
        ];
        return ((agInfo.proposals[_proposalId].approvalCount *
            MULTIPLY_FACTOR) /
            agInfo.guardianCount >=
            SIXTY_PERCENT);
    }
}
