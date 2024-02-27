// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {UserOperation} from "../../../../account-abstraction/contracts/interfaces/UserOperation.sol";
import {IPluginManager} from "./IPluginManager.sol";

// Forge formatter will displace the first comment for the enum field out of the enum itself,
// so annotating here to prevent that.
// forgefmt: disable-start
enum ManifestAssociatedFunctionType {
    /// @notice Function is not defined.
    NONE,
    /// @notice Function belongs to this plugin.
    SELF,
    /// @notice Function belongs to an external plugin provided as a dependency during plugin installation.
    DEPENDENCY,
    /// @notice Resolves to a magic value to always bypass runtime validation for a given function.
    /// This is only assignable on runtime validation functions. If it were to be used on a user op validationFunction,
    /// it would risk burning gas from the account. When used as a hook in any hook location, it is equivalent to not
    /// setting a hook and is therefore disallowed.
    RUNTIME_VALIDATION_ALWAYS_ALLOW,
    /// @notice Resolves to a magic value to always fail in a hook for a given function.
    /// This is only assignable to pre hooks (pre validation and pre execution). It should not be used on
    /// validation functions themselves, because this is equivalent to leaving the validation functions unset.
    /// It should not be used in post-exec hooks, because if it is known to always revert, that should happen
    /// as early as possible to save gas.
    PRE_HOOK_ALWAYS_DENY
}
// forgefmt: disable-end

// For functions of type `ManifestAssociatedFunctionType.DEPENDENCY`, the MSCA MUST find the plugin address
// of the function at `dependencies[dependencyIndex]` during the call to `installPlugin(config)`.
struct ManifestFunction {
    ManifestAssociatedFunctionType functionType;
    uint8 functionId;
    uint256 dependencyIndex;
}

struct ManifestAssociatedFunction {
    bytes4 executionSelector;
    ManifestFunction associatedFunction;
}

struct ManifestExecutionHook {
    bytes4 executionSelector;
    ManifestFunction preExecHook;
    ManifestFunction postExecHook;
}

struct ManifestExternalCallPermission {
    address externalAddress;
    bool permitAnySelector;
    bytes4[] selectors;
}

struct ManifestExecutionFunction {
    bytes4 selector;
    string[] permissions;
}

struct PluginManifest {
    // A human-readable name of the plugin.
    string name;
    // The version of the plugin, following the semantic versioning scheme.
    string version;
    // The author field SHOULD be a username representing the identity of the user or organization
    // that created this plugin.
    string author;
    // List of ERC-165 interfaceIds to add to account to support introspection checks.
    bytes4[] interfaceIds;
    // If this plugin depends on other plugins' validation functions and/or hooks, the interface IDs of
    // those plugins MUST be provided here, with its position in the array matching the `dependencyIndex`
    // members of `ManifestFunction` structs used in the manifest.
    bytes4[] dependencyInterfaceIds;
    // Execution functions defined in this plugin to be installed on the MSCA.
    ManifestExecutionFunction[] executionFunctions;
    // Native functions or execution functions already installed on the MSCA that this plugin will be
    // able to call.
    bytes4[] permittedExecutionSelectors;
    // External contract calls that this plugin will be able to make.
    bool permitAnyExternalContract;
    ManifestExternalCallPermission[] permittedExternalCalls;
    ManifestAssociatedFunction[] userOpValidationFunctions;
    ManifestAssociatedFunction[] runtimeValidationFunctions;
    ManifestAssociatedFunction[] preUserOpValidationHooks;
    ManifestAssociatedFunction[] preRuntimeValidationHooks;
    ManifestExecutionHook[] executionHooks;
    ManifestExecutionHook[] permittedCallHooks;
}

interface IPlugin {
    /// @notice Initialize plugin data for the modular account.
    /// @dev Called by the modular account during `installPlugin`.
    /// @param data Optional bytes array to be decoded and used by the plugin to setup initial plugin data for the
    /// modular account.
    function onInstall(bytes calldata data) external;

    /// @notice Clear plugin data for the modular account.
    /// @dev Called by the modular account during `uninstallPlugin`.
    /// @param data Optional bytes array to be decoded and used by the plugin to clear plugin data for the modular
    /// account.
    function onUninstall(bytes calldata data) external;

    /// @notice Run the pre user operation validation hook specified by the `functionId`.
    /// @dev Pre user operation validation hooks MUST NOT return an authorizer value other than 0 or 1.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param userOp The user operation.
    /// @param userOpHash The user operation hash.
    /// @return Packed validation data for validAfter (6 bytes), validUntil (6 bytes), and authorizer (20 bytes).
    function preUserOpValidationHook(
        uint8 functionId,
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256);

    /// @notice Run the user operation validationFunction specified by the `functionId`.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param userOp The user operation.
    /// @param userOpHash The user operation hash.
    /// @return Packed validation data for validAfter (6 bytes), validUntil (6 bytes), and authorizer (20 bytes).
    function userOpValidationFunction(
        uint8 functionId,
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256);

    /// @notice Run the pre runtime validation hook specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param sender The caller address.
    /// @param value The call value.
    /// @param data The calldata sent.
    function preRuntimeValidationHook(
        uint8 functionId,
        address sender,
        uint256 value,
        bytes calldata data
    ) external;

    /// @notice Run the runtime validationFunction specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param sender The caller address.
    /// @param value The call value.
    /// @param data The calldata sent.
    function runtimeValidationFunction(
        uint8 functionId,
        address sender,
        uint256 value,
        bytes calldata data
    ) external;

    /// @notice Run the pre execution hook specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param sender The caller address.
    /// @param value The call value.
    /// @param data The calldata sent.
    /// @return Context to pass to a post execution hook, if present. An empty bytes array MAY be returned.
    function preExecutionHook(
        uint8 functionId,
        address sender,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);

    /// @notice Run the post execution hook specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param preExecHookData The context returned by its associated pre execution hook.
    function postExecutionHook(
        uint8 functionId,
        bytes calldata preExecHookData
    ) external;

    /// @notice A hook that runs when a hook this plugin owns is installed onto another plugin
    /// @dev Optional, use to implement any required setup logic
    /// @param pluginAppliedOn The plugin that the hook is being applied on
    /// @param injectedHooksInfo Contains pre/post exec hook information
    /// @param data Any optional data for setup
    function onHookApply(
        address pluginAppliedOn,
        IPluginManager.InjectedHooksInfo calldata injectedHooksInfo,
        bytes calldata data
    ) external;

    /// @notice A hook that runs when a hook this plugin owns is unapplied from another plugin
    /// @dev Optional, use to implement any required unapplied logic
    /// @param pluginAppliedOn The plugin that the hook was applied on
    /// @param injectedHooksInfo Contains pre/post exec hook information
    /// @param data Any optional data for the unapplied call
    function onHookUnapply(
        address pluginAppliedOn,
        IPluginManager.InjectedHooksInfo calldata injectedHooksInfo,
        bytes calldata data
    ) external;

    /// @notice Describe the contents and intended configuration of the plugin.
    /// @dev This manifest MUST stay constant over time.
    /// @return A manifest describing the contents and intended configuration of the plugin.
    function pluginManifest() external pure returns (PluginManifest memory);
}
