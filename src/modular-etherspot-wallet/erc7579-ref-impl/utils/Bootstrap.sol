// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../core/ModuleManager.sol";
import "../core/Fallback.sol";
import "../core/HookManager.sol";

import "../interfaces/IModule.sol";

struct BootstrapConfig {
    address module;
    bytes data;
}

contract Bootstrap is ModuleManager, Fallback, HookManager {
    function singleInitMSA(IModule validator, bytes calldata data) external {
        // init validator
        _installValidator(address(validator), data);
    }

    function initMSA(
        BootstrapConfig[] calldata _validators,
        BootstrapConfig[] calldata _executors,
        BootstrapConfig calldata _hook,
        BootstrapConfig calldata _fallback
    ) external {
        // init validators
        for (uint256 i; i < _validators.length; i++) {
            _installValidator(_validators[i].module, _validators[i].data);
        }

        // init executors
        for (uint256 i; i < _executors.length; i++) {
            if (_executors[i].module == address(0)) continue;
            _installExecutor(_executors[i].module, _executors[i].data);
        }

        // init hook
        if (_hook.module != address(0)) {
            _installHook(_hook.module, _hook.data);
        }

        // init fallback
        if (_fallback.module != address(0)) {
            _installFallback(_fallback.module, _fallback.data);
        }
    }

    function _getInitMSACalldata(
        BootstrapConfig[] calldata _validators,
        BootstrapConfig[] calldata _executors,
        BootstrapConfig calldata _hook,
        BootstrapConfig calldata _fallback
    ) external view returns (bytes memory init) {
        init = abi.encode(
            address(this),
            abi.encodeCall(
                this.initMSA,
                (_validators, _executors, _hook, _fallback)
            )
        );
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public pure virtual override(HookManager, ModuleManager) returns (bool) {
        return false;
    }
}
