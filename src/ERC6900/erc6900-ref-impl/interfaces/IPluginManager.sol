// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {FunctionReference} from "../libraries/FunctionReferenceLib.sol";

interface IPluginManager {
    // Pre/post exec hooks added by the user to limit the scope a plugin has
    // These hooks are injected at plugin install time
    struct InjectedHook {
        // The plugin that provides the hook
        address providingPlugin;
        // Either a plugin-defined execution function, or the native function executeFromPluginExternal
        bytes4 selector;
        InjectedHooksInfo injectedHooksInfo;
        bytes hookApplyData;
    }

    struct InjectedHooksInfo {
        uint8 preExecHookFunctionId;
        bool isPostHookUsed;
        uint8 postExecHookFunctionId;
    }

    event PluginInstalled(address indexed plugin, bytes32 manifestHash);
    event PluginUninstalled(
        address indexed plugin,
        bytes32 manifestHash,
        bool onUninstallSucceeded
    );

    /// @notice Install a plugin to the modular account.
    /// @param plugin The plugin to install.
    /// @param manifestHash The hash of the plugin manifest.
    /// @param pluginInitData Optional data to be decoded and used by the plugin to setup initial plugin data for
    /// the modular account.
    /// @param dependencies The dependencies of the plugin, as described in the manifest.
    /// @param injectedHooks Optional hooks to be injected over permitted calls this plugin may make.
    function installPlugin(
        address plugin,
        bytes32 manifestHash,
        bytes calldata pluginInitData,
        FunctionReference[] calldata dependencies,
        InjectedHook[] calldata injectedHooks
    ) external;

    /// @notice Uninstall a plugin from the modular account.
    /// @param plugin The plugin to uninstall.
    /// @param config An optional, implementation-specific field that accounts may use to ensure consistency
    /// guarantees.
    /// @param pluginUninstallData Optional data to be decoded and used by the plugin to clear plugin data for the
    /// modular account.
    /// @param hookUnapplyData Optional data to be decoded and used by the plugin to clear injected hooks for the
    /// modular account.
    function uninstallPlugin(
        address plugin,
        bytes calldata config,
        bytes calldata pluginUninstallData,
        bytes[] calldata hookUnapplyData
    ) external;
}
