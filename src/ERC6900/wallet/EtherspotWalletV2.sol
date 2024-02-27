// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IEntryPoint} from "../../../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {UserOperation} from "../../../account-abstraction/contracts/interfaces/UserOperation.sol";
import {BaseAccount} from "../../../account-abstraction/contracts/core/BaseAccount.sol";

import {BaseModularAccount} from "../erc6900-ref-impl/account/BaseModularAccount.sol";
import {BaseModularAccountLoupe} from "../erc6900-ref-impl/account/BaseModularAccountLoupe.sol";
import {IPlugin, PluginManifest} from "../erc6900-ref-impl/interfaces/IPlugin.sol";
import {IStandardExecutor} from "../erc6900-ref-impl/interfaces/IStandardExecutor.sol";
import {IPluginExecutor} from "../erc6900-ref-impl/interfaces/IPluginExecutor.sol";
import {AccountStorage, getAccountStorage, getPermittedCallKey} from "../erc6900-ref-impl/libraries/AccountStorage.sol";
import {Execution} from "../erc6900-ref-impl/libraries/ERC6900TypeUtils.sol";
import {FunctionReference, FunctionReferenceLib} from "../erc6900-ref-impl/libraries/FunctionReferenceLib.sol";
import {AccountStorageInitializable} from "../erc6900-ref-impl/account/AccountStorageInitializable.sol";
import {IPluginManager} from "../erc6900-ref-impl/interfaces/IPluginManager.sol";
import {_coalescePreValidation, _coalesceValidation} from "../erc6900-ref-impl/helpers/ValidationDataHelpers.sol";

import {ErrorsLib} from "../libraries/ErrorsLib.sol";

contract EtherspotWalletV2 is
    IPluginManager,
    BaseAccount,
    BaseModularAccount,
    BaseModularAccountLoupe,
    UUPSUpgradeable,
    AccountStorageInitializable,
    IStandardExecutor,
    IPluginExecutor
{
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct PostExecToRun {
        bytes preExecHookReturnData;
        FunctionReference postExecHook;
    }

    IEntryPoint private immutable _ENTRY_POINT;

    event ModularAccountInitialized(IEntryPoint indexed entryPoint);

    // Wraps execution of a native function with runtime validation and hooks
    // Used for upgradeTo, upgradeToAndCall, execute, executeBatch, installPlugin, uninstallPlugin
    modifier wrapNativeFunction() {
        _doRuntimeValidationIfNotFromEP();

        PostExecToRun[] memory postExecHooks = _doPreExecHooks(msg.sig);

        _;

        _doCachedPostExecHooks(postExecHooks);
    }

    constructor(IEntryPoint anEntryPoint) {
        _ENTRY_POINT = anEntryPoint;
        _disableInitializers();
    }

    // EXTERNAL FUNCTIONS

    /// @notice Initializes the account with a set of plugins
    /// @dev No dependencies or hooks can be injected with this installation
    /// @param plugins The plugins to install
    /// @param manifestHashes The manifest hashes of the plugins to install
    /// @param pluginInstallDatas The plugin install datas of the plugins to install
    function initialize(
        address[] memory plugins,
        bytes32[] memory manifestHashes,
        bytes[] memory pluginInstallDatas
    ) external initializer {
        uint256 length = plugins.length;

        if (
            length != manifestHashes.length ||
            length != pluginInstallDatas.length
        ) {
            revert ArrayLengthMismatch();
        }

        FunctionReference[] memory emptyDependencies = new FunctionReference[](
            0
        );
        IPluginManager.InjectedHook[]
            memory emptyInjectedHooks = new IPluginManager.InjectedHook[](0);

        for (uint256 i = 0; i < length; ) {
            _installPlugin(
                plugins[i],
                manifestHashes[i],
                pluginInstallDatas[i],
                emptyDependencies,
                emptyInjectedHooks
            );

            unchecked {
                ++i;
            }
        }

        emit ModularAccountInitialized(_ENTRY_POINT);
    }

    receive() external payable {}

    /// @notice Fallback function
    /// @dev We route calls to execution functions based on incoming msg.sig
    /// @dev If there's no plugin associated with this function selector, revert
    fallback(bytes calldata) external payable returns (bytes memory) {
        address execPlugin = getAccountStorage().selectorData[msg.sig].plugin;
        if (execPlugin == address(0)) {
            revert ErrorsLib.UnrecognizedFunction(msg.sig);
        }

        _doRuntimeValidationIfNotFromEP();

        PostExecToRun[] memory postExecHooks;
        // Cache post-exec hooks in memory
        postExecHooks = _doPreExecHooks(msg.sig);

        // execute the function, bubbling up any reverts
        (bool execSuccess, bytes memory execReturnData) = execPlugin.call(
            msg.data
        );

        if (!execSuccess) {
            // Bubble up revert reasons from plugins
            assembly ("memory-safe") {
                revert(add(execReturnData, 32), mload(execReturnData))
            }
        }

        _doCachedPostExecHooks(postExecHooks);

        return execReturnData;
    }

    /// @notice Executes a transaction from the account
    /// @param execution The execution to perform
    /// @return result The result of the execution
    function execute(
        Execution calldata execution
    )
        external
        payable
        override
        wrapNativeFunction
        returns (bytes memory result)
    {
        result = _exec(execution.target, execution.value, execution.data);
    }

    /// @notice Executes a batch of transactions from the account
    /// @dev If any of the transactions revert, the entire batch reverts
    /// @param executions The executions to perform
    /// @return results The results of the executions
    function executeBatch(
        Execution[] calldata executions
    )
        external
        payable
        override
        wrapNativeFunction
        returns (bytes[] memory results)
    {
        uint256 executionsLength = executions.length;
        results = new bytes[](executionsLength);

        for (uint256 i = 0; i < executionsLength; ) {
            results[i] = _exec(
                executions[i].target,
                executions[i].value,
                executions[i].data
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Executes a call from a plugin to another plugin
    /// @dev Permissions must be granted to the calling plugin for the call to go through
    /// @param data calldata to send to the plugin
    /// @return The result of the call
    function executeFromPlugin(
        bytes calldata data
    ) external payable override returns (bytes memory) {
        bytes4 selector = bytes4(data[:4]);
        address callingPlugin = msg.sender;

        bytes24 execFromPluginKey = getPermittedCallKey(
            callingPlugin,
            selector
        );

        AccountStorage storage _storage = getAccountStorage();

        if (!_storage.permittedCalls[execFromPluginKey].callPermitted) {
            revert ErrorsLib.ExecFromPluginNotPermitted(
                callingPlugin,
                selector
            );
        }

        PostExecToRun[]
            memory postPermittedCallHooks = _doPrePermittedCallHooks(
                selector,
                callingPlugin
            );

        address execFunctionPlugin = _storage.selectorData[selector].plugin;

        if (execFunctionPlugin == address(0)) {
            revert ErrorsLib.UnrecognizedFunction(selector);
        }

        PostExecToRun[] memory postExecHooks = _doPreExecHooks(selector);

        (bool success, bytes memory returnData) = execFunctionPlugin.call(data);

        if (!success) {
            assembly ("memory-safe") {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        _doCachedPostExecHooks(postExecHooks);
        _doCachedPostExecHooks(postPermittedCallHooks);

        return returnData;
    }

    /// @notice Executes a call from a plugin to a non-plugin address
    /// @dev Permissions must be granted to the calling plugin for the call to go through
    /// @param target address of the target to call
    /// @param value value to send with the call
    /// @param data calldata to send to the target
    /// @return The result of the call
    function executeFromPluginExternal(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory) {
        bytes4 selector = bytes4(data);
        AccountStorage storage _storage = getAccountStorage();

        // Check the caller plugin's permission to make this call

        // Check the target contract permission.
        // This first checks that the intended target is permitted at all. If it is, then it checks if any selector
        // is permitted. If any selector is permitted, then it skips the selector-level permission check.
        // If only a subset of selectors are permitted, then it also checks the selector-level permission.
        // By checking in the order of [address specified with any selector allowed], [any address allowed],
        // [address specified and selector specified], along with the extra bool `permittedCall`, we can
        // reduce the number of `sload`s in the worst-case from 3 down to 2.
        bool targetContractPermittedCall = _storage
        .permittedExternalCalls[IPlugin(msg.sender)][target].addressPermitted &&
            (_storage
            .permittedExternalCalls[IPlugin(msg.sender)][target]
                .anySelectorPermitted ||
                _storage
                .permittedExternalCalls[IPlugin(msg.sender)][target]
                    .permittedSelectors[selector]);

        // If the target contract is not permitted, check if the caller plugin is permitted to make any external
        // calls.
        if (
            !(targetContractPermittedCall ||
                _storage.pluginData[msg.sender].anyExternalExecPermitted)
        ) {
            revert ErrorsLib.ExecFromPluginExternalNotPermitted(
                msg.sender,
                target,
                value,
                data
            );
        }

        // Run any pre plugin exec specific to this caller and the `executeFromPluginExternal` selector

        PostExecToRun[]
            memory postPermittedCallHooks = _doPrePermittedCallHooks(
                IPluginExecutor.executeFromPluginExternal.selector,
                msg.sender
            );

        // Run any pre exec hooks for this selector
        PostExecToRun[] memory postExecHooks = _doPreExecHooks(
            IPluginExecutor.executeFromPluginExternal.selector
        );

        // Perform the external call
        bytes memory returnData = _exec(target, value, data);

        // Run any post exec hooks for this selector
        _doCachedPostExecHooks(postExecHooks);

        // Run any post exec hooks specific to this caller and the `executeFromPluginExternal` selector
        _doCachedPostExecHooks(postPermittedCallHooks);

        return returnData;
    }

    /// @inheritdoc IPluginManager
    function installPlugin(
        address plugin,
        bytes32 manifestHash,
        bytes calldata pluginInitData,
        FunctionReference[] calldata dependencies,
        InjectedHook[] calldata injectedHooks
    ) external override wrapNativeFunction {
        _installPlugin(
            plugin,
            manifestHash,
            pluginInitData,
            dependencies,
            injectedHooks
        );
    }

    /// @inheritdoc IPluginManager
    function uninstallPlugin(
        address plugin,
        bytes calldata config,
        bytes calldata pluginUninstallData,
        bytes[] calldata hookUnapplyData
    ) external override wrapNativeFunction {
        PluginManifest memory manifest;

        if (config.length > 0) {
            manifest = abi.decode(config, (PluginManifest));
        } else {
            manifest = IPlugin(plugin).pluginManifest();
        }

        _uninstallPlugin(
            plugin,
            manifest,
            pluginUninstallData,
            hookUnapplyData
        );
    }

    /// @notice ERC165 introspection
    /// @dev returns true for `IERC165.interfaceId` and false for `0xFFFFFFFF`
    /// @param interfaceId interface id to check against
    /// @return bool support for specific interface
    function supportsInterface(
        bytes4 interfaceId
    ) external view override returns (bool) {
        if (interfaceId == _INTERFACE_ID_INVALID) {
            return false;
        }
        if (interfaceId == _IERC165_INTERFACE_ID) {
            return true;
        }

        return getAccountStorage().supportedIfaces[interfaceId] > 0;
    }

    /// @inheritdoc UUPSUpgradeable
    function upgradeTo(
        address newImplementation
    ) public override onlyProxy wrapNativeFunction {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /// @inheritdoc UUPSUpgradeable
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) public payable override onlyProxy wrapNativeFunction {
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /// @notice Gets the entry point for this account
    /// @return entryPoint The entry point for this account
    function entryPoint() public view override returns (IEntryPoint) {
        return _ENTRY_POINT;
    }

    // INTERNAL FUNCTIONS

    // Parent function validateUserOp enforces that this call can only be made by the EntryPoint
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        if (userOp.callData.length < 4) {
            revert ErrorsLib.UnrecognizedFunction(bytes4(userOp.callData));
        }
        bytes4 selector = bytes4(userOp.callData);

        FunctionReference userOpValidationFunction = getAccountStorage()
            .selectorData[selector]
            .userOpValidation;

        validationData = _doUserOpValidation(
            selector,
            userOpValidationFunction,
            userOp,
            userOpHash
        );
    }

    // To support gas estimation, we don't fail early when the failure is caused by a signature failure
    function _doUserOpValidation(
        bytes4 selector,
        FunctionReference userOpValidationFunction,
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal returns (uint256 validationData) {
        if (
            userOpValidationFunction ==
            FunctionReferenceLib._EMPTY_FUNCTION_REFERENCE
        ) {
            revert ErrorsLib.UserOpValidationFunctionMissing(selector);
        }

        uint256 currentValidationData;

        // Do preUserOpValidation hooks
        EnumerableSet.Bytes32Set
            storage preUserOpValidationHooks = getAccountStorage()
                .selectorData[selector]
                .preUserOpValidationHooks;

        uint256 preUserOpValidationHooksLength = preUserOpValidationHooks
            .length();
        for (uint256 i = 0; i < preUserOpValidationHooksLength; ) {
            // FunctionReference preUserOpValidationHook = preUserOpValidationHooks[i];

            if (
                !_toFunctionReference(preUserOpValidationHooks.at(i))
                    .isEmptyOrMagicValue()
            ) {
                (address plugin, uint8 functionId) = _toFunctionReference(
                    preUserOpValidationHooks.at(i)
                ).unpack();
                try
                    IPlugin(plugin).preUserOpValidationHook(
                        functionId,
                        userOp,
                        userOpHash
                    )
                returns (uint256 returnData) {
                    currentValidationData = returnData;
                } catch {
                    currentValidationData = SIG_VALIDATION_FAILED;
                }

                if (uint160(currentValidationData) > 1) {
                    // If the aggregator is not 0 or 1, it is an unexpected value
                    revert ErrorsLib.UnexpectedAggregator(
                        plugin,
                        functionId,
                        address(uint160(currentValidationData))
                    );
                }
                validationData = _coalescePreValidation(
                    validationData,
                    currentValidationData
                );
            } else {
                // Function reference cannot be 0 and _RUNTIME_VALIDATION_ALWAYS_ALLOW is not permitted here.
                revert ErrorsLib.InvalidConfiguration();
            }

            unchecked {
                ++i;
            }
        }

        // Run the user op validationFunction
        {
            if (!userOpValidationFunction.isEmptyOrMagicValue()) {
                (address plugin, uint8 functionId) = userOpValidationFunction
                    .unpack();
                try
                    IPlugin(plugin).userOpValidationFunction(
                        functionId,
                        userOp,
                        userOpHash
                    )
                returns (uint256 returnData) {
                    currentValidationData = returnData;
                } catch {
                    currentValidationData = SIG_VALIDATION_FAILED;
                }
                if (preUserOpValidationHooksLength != 0) {
                    // If we have other validation data we need to coalesce with
                    validationData = _coalesceValidation(
                        validationData,
                        currentValidationData
                    );
                } else {
                    validationData = currentValidationData;
                }
            } else {
                // _RUNTIME_VALIDATION_ALWAYS_ALLOW and _PRE_HOOK_ALWAYS_DENY is not permitted here.
                revert ErrorsLib.InvalidConfiguration();
            }
        }
    }

    function _doRuntimeValidationIfNotFromEP() internal {
        if (msg.sender == address(_ENTRY_POINT)) return;

        AccountStorage storage _storage = getAccountStorage();
        FunctionReference runtimeValidationFunction = _storage
            .selectorData[msg.sig]
            .runtimeValidation;
        // run all preRuntimeValidation hooks
        EnumerableSet.Bytes32Set
            storage preRuntimeValidationHooks = getAccountStorage()
                .selectorData[msg.sig]
                .preRuntimeValidationHooks;

        uint256 preRuntimeValidationHooksLength = preRuntimeValidationHooks
            .length();
        for (uint256 i = 0; i < preRuntimeValidationHooksLength; ) {
            FunctionReference preRuntimeValidationHook = _toFunctionReference(
                preRuntimeValidationHooks.at(i)
            );

            if (!preRuntimeValidationHook.isEmptyOrMagicValue()) {
                (address plugin, uint8 functionId) = preRuntimeValidationHook
                    .unpack();
                // solhint-disable-next-line no-empty-blocks
                try
                    IPlugin(plugin).preRuntimeValidationHook(
                        functionId,
                        msg.sender,
                        msg.value,
                        msg.data
                    )
                {} catch (bytes memory revertReason) {
                    revert ErrorsLib.PreRuntimeValidationHookFailed(
                        plugin,
                        functionId,
                        revertReason
                    );
                }

                unchecked {
                    ++i;
                }
            } else {
                if (
                    preRuntimeValidationHook ==
                    FunctionReferenceLib._PRE_HOOK_ALWAYS_DENY
                ) {
                    revert ErrorsLib.AlwaysDenyRule();
                }
                // Function reference cannot be 0 or _RUNTIME_VALIDATION_ALWAYS_ALLOW.
                revert ErrorsLib.InvalidConfiguration();
            }
        }

        // Identifier scope limiting
        {
            if (!runtimeValidationFunction.isEmptyOrMagicValue()) {
                (address plugin, uint8 functionId) = runtimeValidationFunction
                    .unpack();
                // solhint-disable-next-line no-empty-blocks
                try
                    IPlugin(plugin).runtimeValidationFunction(
                        functionId,
                        msg.sender,
                        msg.value,
                        msg.data
                    )
                {} catch (bytes memory revertReason) {
                    revert ErrorsLib.RuntimeValidationFunctionReverted(
                        plugin,
                        functionId,
                        revertReason
                    );
                }
            } else {
                if (
                    runtimeValidationFunction ==
                    FunctionReferenceLib._EMPTY_FUNCTION_REFERENCE
                ) {
                    revert ErrorsLib.RuntimeValidationFunctionMissing(msg.sig);
                } else if (
                    runtimeValidationFunction ==
                    FunctionReferenceLib._PRE_HOOK_ALWAYS_DENY
                ) {
                    revert ErrorsLib.InvalidConfiguration();
                }
                // If _RUNTIME_VALIDATION_ALWAYS_ALLOW, just let the function finish.
            }
        }
    }

    function _doPreExecHooks(
        bytes4 selector
    ) internal returns (PostExecToRun[] memory postHooksToRun) {
        EnumerableSet.Bytes32Set storage preExecHooks = getAccountStorage()
            .selectorData[selector]
            .preExecHooks;

        uint256 postExecHooksLength = 0;
        uint256 preExecHooksLength = preExecHooks.length();

        // Over-allocate on length, but not all of this may get filled up.
        postHooksToRun = new PostExecToRun[](preExecHooksLength);
        for (uint256 i = 0; i < preExecHooksLength; ) {
            FunctionReference preExecHook = _toFunctionReference(
                preExecHooks.at(i)
            );

            if (preExecHook.isEmptyOrMagicValue()) {
                if (preExecHook == FunctionReferenceLib._PRE_HOOK_ALWAYS_DENY) {
                    revert ErrorsLib.AlwaysDenyRule();
                }
                // Function reference cannot be 0. If _RUNTIME_VALIDATION_ALWAYS_ALLOW, revert since it's an
                // invalid configuration.
                revert ErrorsLib.InvalidConfiguration();
            }

            (address plugin, uint8 functionId) = preExecHook.unpack();
            bytes memory preExecHookReturnData;
            try
                IPlugin(plugin).preExecutionHook(
                    functionId,
                    msg.sender,
                    msg.value,
                    msg.data
                )
            returns (bytes memory returnData) {
                preExecHookReturnData = returnData;
            } catch (bytes memory revertReason) {
                revert ErrorsLib.PreExecHookReverted(
                    plugin,
                    functionId,
                    revertReason
                );
            }

            // Check to see if there is a postExec hook set for this preExec hook
            FunctionReference postExecHook = getAccountStorage()
                .selectorData[selector]
                .associatedPostExecHooks[preExecHook];
            if (
                postExecHook != FunctionReferenceLib._EMPTY_FUNCTION_REFERENCE
            ) {
                postHooksToRun[postExecHooksLength].postExecHook = postExecHook;
                postHooksToRun[postExecHooksLength]
                    .preExecHookReturnData = preExecHookReturnData;
                unchecked {
                    ++postExecHooksLength;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function _doPrePermittedCallHooks(
        bytes4 executionSelector,
        address callerPlugin
    ) internal returns (PostExecToRun[] memory postHooksToRun) {
        bytes24 permittedCallKey = getPermittedCallKey(
            callerPlugin,
            executionSelector
        );

        EnumerableSet.Bytes32Set storage preExecHooks = getAccountStorage()
            .permittedCalls[permittedCallKey]
            .prePermittedCallHooks;

        uint256 postExecHooksLength = 0;
        uint256 preExecHooksLength = preExecHooks.length();
        postHooksToRun = new PostExecToRun[](preExecHooksLength); // Over-allocate on length, but not all of this
        // may get filled up.
        for (uint256 i = 0; i < preExecHooksLength; ) {
            FunctionReference preExecHook = _toFunctionReference(
                preExecHooks.at(i)
            );

            if (preExecHook.isEmptyOrMagicValue()) {
                if (preExecHook == FunctionReferenceLib._PRE_HOOK_ALWAYS_DENY) {
                    revert ErrorsLib.AlwaysDenyRule();
                }
                // Function reference cannot be 0. If RUNTIME_VALIDATION_BYPASS, revert since it's an invalid
                // configuration.
                revert ErrorsLib.InvalidConfiguration();
            }

            (address plugin, uint8 functionId) = preExecHook.unpack();
            bytes memory preExecHookReturnData;
            try
                IPlugin(plugin).preExecutionHook(
                    functionId,
                    msg.sender,
                    msg.value,
                    msg.data
                )
            returns (bytes memory returnData) {
                preExecHookReturnData = returnData;
            } catch (bytes memory revertReason) {
                revert ErrorsLib.PreExecHookReverted(
                    plugin,
                    functionId,
                    revertReason
                );
            }

            // Check to see if there is a postExec hook set for this preExec hook
            FunctionReference postExecHook = getAccountStorage()
                .permittedCalls[permittedCallKey]
                .associatedPostPermittedCallHooks[preExecHook];
            if (FunctionReference.unwrap(postExecHook) != 0) {
                postHooksToRun[postExecHooksLength].postExecHook = postExecHook;
                postHooksToRun[postExecHooksLength]
                    .preExecHookReturnData = preExecHookReturnData;
                unchecked {
                    ++postExecHooksLength;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function _doCachedPostExecHooks(
        PostExecToRun[] memory postHooksToRun
    ) internal {
        uint256 postHooksToRunLength = postHooksToRun.length;
        for (uint256 i = 0; i < postHooksToRunLength; ) {
            PostExecToRun memory postHookToRun = postHooksToRun[i];
            FunctionReference postExecHook = postHookToRun.postExecHook;
            if (
                postExecHook == FunctionReferenceLib._EMPTY_FUNCTION_REFERENCE
            ) {
                // Reached the end of runnable postExec hooks, stop.
                // Array may be over-allocated.
                return;
            }
            (address plugin, uint8 functionId) = postHookToRun
                .postExecHook
                .unpack();
            // solhint-disable-next-line no-empty-blocks
            try
                IPlugin(plugin).postExecutionHook(
                    functionId,
                    postHookToRun.preExecHookReturnData
                )
            {} catch (bytes memory revertReason) {
                revert ErrorsLib.PostExecHookReverted(
                    plugin,
                    functionId,
                    revertReason
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override {}
}
