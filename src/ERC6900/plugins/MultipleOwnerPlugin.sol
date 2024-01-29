// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {UserOperation} from "@ERC4337/interfaces/UserOperation.sol";

import {EtherspotWalletV2, UUPSUpgradeable} from "../wallet/EtherspotWalletV2.sol";
import {ArrayLib} from "../libraries/ArrayLib.sol";
import {ErrorsLib} from "../libraries/ErrorsLib.sol";
import {IMultipleOwnerPlugin} from "../interfaces/IMultipleOwnerPlugin.sol";

import {ManifestFunction, ManifestAssociatedFunctionType, ManifestAssociatedFunction, PluginManifest, ManifestExecutionFunction} from "@ERC6900/src/interfaces/IPlugin.sol";
import {IStandardExecutor} from "@ERC6900/src/interfaces/IStandardExecutor.sol";
import {BasePlugin} from "@ERC6900/src/plugins/BasePlugin.sol";

contract MultipleOwnerPlugin is BasePlugin, IMultipleOwnerPlugin {
    using ECDSA for bytes32;

    string public constant NAME = "Multiple Owner Plugin";
    string public constant VERSION = "1.0.0";
    string public constant AUTHOR = "Etherspot";

    uint256 internal constant _SIG_VALIDATION_PASSED = 0;
    uint256 internal constant _SIG_VALIDATION_FAILED = 1;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant _1271_MAGIC_VALUE = 0x1626ba7e;

    mapping(address => address[]) internal _multipleOwners;

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Execution functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    /// @inheritdoc IMultipleOwnerPlugin
    function addOwner(address _account, address _newOwner) external {
        if (isOwnerOfAccount(_account, _newOwner))
            revert ErrorsLib.AlreadyAnOwner();
        _addOwner(_account, _newOwner);
        emit OwnerAdded(_account, _newOwner);
    }

    /// @inheritdoc IMultipleOwnerPlugin
    function removeOwner(address _account, address _owner) external {
        if (!isOwnerOfAccount(_account, _owner)) revert ErrorsLib.NotAnOwner();
        _removeOwner(_account, _owner);
        emit OwnerRemoved(_account, _owner);
    }

    /// @inheritdoc IMultipleOwnerPlugin
    function transferOwnership(address newOwner) external {
        _transferOwnership(newOwner);
    }

    /// This function is an issue with using IERC1271.
    /// It can work using ECDSA.recover to obtain the signer from the digest
    /// and pass that into isValidSignatureNow call.
    /// However, when signing from an SCW, this fails due to ECDSA for SCWs
    /// Will need to divert from IERC1271 standard but still follow return values
    function isValidSig(
        address _signer,
        bytes32 _digest,
        bytes calldata _signature
    ) external view returns (bytes4) {
        if (isOwner(_signer)) {
            SignatureChecker.isValidSignatureNow(_signer, _digest, _signature);
            return _1271_MAGIC_VALUE;
        }
        return 0xffffffff;
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Plugin view functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    /// @inheritdoc IMultipleOwnerPlugin
    function owners() public view returns (address[] memory) {
        return _multipleOwners[msg.sender];
    }

    /// @inheritdoc IMultipleOwnerPlugin
    function ownersOf(address _account) public view returns (address[] memory) {
        return _multipleOwners[_account];
    }

    /// @inheritdoc IMultipleOwnerPlugin
    function isOwner(address _owner) public view returns (bool) {
        if (ArrayLib._contains(_multipleOwners[msg.sender], _owner)) {
            return true;
        }
        return false;
    }

    /// @inheritdoc IMultipleOwnerPlugin
    function isOwnerOfAccount(
        address _account,
        address _owner
    ) public view returns (bool) {
        if (ArrayLib._contains(_multipleOwners[_account], _owner)) {
            return true;
        }
        return false;
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Plugin interface functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    /// @inheritdoc BasePlugin
    function onInstall(bytes calldata data) external override {
        _transferOwnership(abi.decode(data, (address)));
    }

    /// @inheritdoc BasePlugin
    function onUninstall(bytes calldata) external override {
        _transferOwnership(address(0));
    }

    /// modified from original - checks sender not in _multipleOwners
    /// @inheritdoc BasePlugin
    function runtimeValidationFunction(
        uint8 functionId,
        address sender,
        uint256,
        bytes calldata
    ) external view override {
        if (functionId == uint8(FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF)) {
            // Validate that the sender is an owner of the account or self.
            if (!isOwnerOfAccount(msg.sender, sender) && sender != msg.sender) {
                revert ErrorsLib.NotAuthorized();
            }
            return;
        }
        revert NotImplemented();
    }

    /// modified from original - checks signer not in _multipleOwners
    /// @inheritdoc BasePlugin
    function userOpValidationFunction(
        uint8 functionId,
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external view override returns (uint256) {
        if (functionId == uint8(FunctionId.USER_OP_VALIDATION_OWNER)) {
            // Validate the user op signature against the owners.
            (address signer, ) = (userOpHash.toEthSignedMessageHash())
                .tryRecover(userOp.signature);
            if (signer == address(0) || !isOwnerOfAccount(msg.sender, signer)) {
                return _SIG_VALIDATION_FAILED;
            }
            return _SIG_VALIDATION_PASSED;
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

        manifest.executionFunctions = new ManifestExecutionFunction[](8);
        manifest.executionFunctions[0] = ManifestExecutionFunction(
            this.transferOwnership.selector,
            new string[](0)
        );
        manifest.executionFunctions[1] = ManifestExecutionFunction(
            this.isValidSig.selector,
            new string[](0)
        );
        manifest.executionFunctions[2] = ManifestExecutionFunction(
            this.owners.selector,
            new string[](0)
        );
        manifest.executionFunctions[3] = ManifestExecutionFunction(
            this.isOwner.selector,
            new string[](0)
        );
        manifest.executionFunctions[4] = ManifestExecutionFunction(
            this.isOwnerOfAccount.selector,
            new string[](0)
        );
        manifest.executionFunctions[5] = ManifestExecutionFunction(
            this.ownersOf.selector,
            new string[](0)
        );
        manifest.executionFunctions[6] = ManifestExecutionFunction(
            this.addOwner.selector,
            new string[](0)
        );
        manifest.executionFunctions[7] = ManifestExecutionFunction(
            this.removeOwner.selector,
            new string[](0)
        );

        ManifestFunction
            memory ownerUserOpValidationFunction = ManifestFunction({
                functionType: ManifestAssociatedFunctionType.SELF,
                functionId: uint8(FunctionId.USER_OP_VALIDATION_OWNER),
                dependencyIndex: 0 // Unused.
            });
        manifest.userOpValidationFunctions = new ManifestAssociatedFunction[](
            7
        );
        manifest.userOpValidationFunctions[0] = ManifestAssociatedFunction({
            executionSelector: this.transferOwnership.selector,
            associatedFunction: ownerUserOpValidationFunction
        });
        manifest.userOpValidationFunctions[1] = ManifestAssociatedFunction({
            executionSelector: IStandardExecutor.execute.selector,
            associatedFunction: ownerUserOpValidationFunction
        });
        manifest.userOpValidationFunctions[2] = ManifestAssociatedFunction({
            executionSelector: IStandardExecutor.executeBatch.selector,
            associatedFunction: ownerUserOpValidationFunction
        });
        manifest.userOpValidationFunctions[3] = ManifestAssociatedFunction({
            executionSelector: EtherspotWalletV2.installPlugin.selector,
            associatedFunction: ownerUserOpValidationFunction
        });
        manifest.userOpValidationFunctions[4] = ManifestAssociatedFunction({
            executionSelector: EtherspotWalletV2.uninstallPlugin.selector,
            associatedFunction: ownerUserOpValidationFunction
        });
        manifest.userOpValidationFunctions[5] = ManifestAssociatedFunction({
            executionSelector: UUPSUpgradeable.upgradeTo.selector,
            associatedFunction: ownerUserOpValidationFunction
        });
        manifest.userOpValidationFunctions[6] = ManifestAssociatedFunction({
            executionSelector: UUPSUpgradeable.upgradeToAndCall.selector,
            associatedFunction: ownerUserOpValidationFunction
        });

        ManifestFunction
            memory ownerOrSelfRuntimeValidationFunction = ManifestFunction({
                functionType: ManifestAssociatedFunctionType.SELF,
                functionId: uint8(FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF),
                dependencyIndex: 0 // Unused.
            });
        ManifestFunction memory alwaysAllowFunction = ManifestFunction({
            functionType: ManifestAssociatedFunctionType
                .RUNTIME_VALIDATION_ALWAYS_ALLOW,
            functionId: 0, // Unused.
            dependencyIndex: 0 // Unused.
        });
        manifest.runtimeValidationFunctions = new ManifestAssociatedFunction[](
            14
        );
        manifest.runtimeValidationFunctions[0] = ManifestAssociatedFunction({
            executionSelector: this.transferOwnership.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[1] = ManifestAssociatedFunction({
            executionSelector: this.owners.selector,
            associatedFunction: alwaysAllowFunction
        });
        manifest.runtimeValidationFunctions[2] = ManifestAssociatedFunction({
            executionSelector: IStandardExecutor.execute.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[3] = ManifestAssociatedFunction({
            executionSelector: IStandardExecutor.executeBatch.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[4] = ManifestAssociatedFunction({
            executionSelector: EtherspotWalletV2.installPlugin.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[5] = ManifestAssociatedFunction({
            executionSelector: EtherspotWalletV2.uninstallPlugin.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[6] = ManifestAssociatedFunction({
            executionSelector: UUPSUpgradeable.upgradeTo.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[7] = ManifestAssociatedFunction({
            executionSelector: UUPSUpgradeable.upgradeToAndCall.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[8] = ManifestAssociatedFunction({
            executionSelector: this.isValidSig.selector,
            associatedFunction: alwaysAllowFunction
        });
        manifest.runtimeValidationFunctions[9] = ManifestAssociatedFunction({
            executionSelector: this.addOwner.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[10] = ManifestAssociatedFunction({
            executionSelector: this.removeOwner.selector,
            associatedFunction: ownerOrSelfRuntimeValidationFunction
        });
        manifest.runtimeValidationFunctions[11] = ManifestAssociatedFunction({
            executionSelector: this.isOwner.selector,
            associatedFunction: alwaysAllowFunction
        });
        manifest.runtimeValidationFunctions[12] = ManifestAssociatedFunction({
            executionSelector: this.isOwnerOfAccount.selector,
            associatedFunction: ManifestFunction({
                functionType: ManifestAssociatedFunctionType
                    .RUNTIME_VALIDATION_ALWAYS_ALLOW,
                functionId: 0,
                dependencyIndex: 0
            })
        });
        manifest.runtimeValidationFunctions[13] = ManifestAssociatedFunction({
            executionSelector: this.ownersOf.selector,
            associatedFunction: alwaysAllowFunction
        });

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
            interfaceId == type(IMultipleOwnerPlugin).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Internal / Private functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    function _transferOwnership(address _newOwner) internal {
        address previousOwner;
        if (_newOwner == address(0)) {
            /// address(0) should only be on `uninstallPlugin`
            previousOwner = _multipleOwners[msg.sender][0];
            delete _multipleOwners[msg.sender];
        } else if (_multipleOwners[msg.sender].length == 0) {
            /// empty _multipleOwners should only be on `installPlugin`
            _multipleOwners[msg.sender].push(_newOwner);
        } else {
            /// due to limited flexibility of BasePlugin: _multipleOwners[0] will be "main" owner
            previousOwner = _multipleOwners[msg.sender][0];
            _multipleOwners[msg.sender][0] = _newOwner;
        }
        emit OwnershipTransferred(msg.sender, previousOwner, _newOwner);
    }

    function _addOwner(address _account, address _newOwner) internal {
        _multipleOwners[_account].push(_newOwner);
    }

    function _removeOwner(address _account, address _owner) internal {
        ArrayLib._removeElement(_multipleOwners[_account], _owner);
    }
}
