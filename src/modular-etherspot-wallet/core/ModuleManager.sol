// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {SentinelListLib, SENTINEL} from "../erc7579-ref-impl/libs/SentinelList.sol";
import {CallType, CALLTYPE_SINGLE, CALLTYPE_DELEGATECALL, CALLTYPE_STATIC} from "../erc7579-ref-impl/libs/ModeLib.sol";
import {AccountBase} from "../erc7579-ref-impl/core/AccountBase.sol";
import "../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "forge-std/interfaces/IERC165.sol";
import "../erc7579-ref-impl/core/Receiver.sol";

/**
 * @title ModuleManager
 * @author lbw33 (inspiration from zeroknots.eth | rhinestone.wtf)
 * @dev This contract manages Validator, Executor and Fallback modules for the MSA
 * @dev it uses SentinelList to manage the linked list of modules
 * @dev This is a modified version of the ERC7579 ModuleManager contract
 * @dev to add
 * NOTE: the linked list is just an example. accounts may implement this differently
 */
abstract contract ModuleManager is AccountBase, Receiver {
    using SentinelListLib for SentinelListLib.SentinelList;

    error InvalidModule(address module);
    error CannotRemoveLastValidator();

    // keccak256("modulemanager.storage.msa");
    bytes32 internal constant MODULEMANAGER_STORAGE_LOCATION =
        0xf88ce1fdb7fb1cbd3282e49729100fa3f2d6ee9f797961fe4fb1871cea89ea02;

    /// @custom:storage-location erc7201:modulemanager.storage.msa
    struct ModuleManagerStorage {
        // linked list of validators. List is initialized by initializeAccount()
        SentinelListLib.SentinelList $valdiators;
        // linked list of executors. List is initialized by initializeAccount()
        SentinelListLib.SentinelList $executors;
    }

    function $moduleManager()
        internal
        pure
        virtual
        returns (ModuleManagerStorage storage $ims)
    {
        bytes32 position = MODULEMANAGER_STORAGE_LOCATION;
        assembly {
            $ims.slot := position
        }
    }

    modifier onlyExecutorModule() {
        SentinelListLib.SentinelList storage $executors = $moduleManager()
            .$executors;
        if (!$executors.contains(msg.sender)) revert InvalidModule(msg.sender);
        _;
    }

    modifier onlyValidatorModule(address validator) {
        SentinelListLib.SentinelList storage $valdiators = $moduleManager()
            .$valdiators;
        if (!$valdiators.contains(validator)) revert InvalidModule(validator);
        _;
    }

    function _initModuleManager() internal virtual {
        ModuleManagerStorage storage $ims = $moduleManager();
        $ims.$executors.init();
        $ims.$valdiators.init();
    }

    function isAlreadyInitialized() internal view virtual returns (bool) {
        ModuleManagerStorage storage $ims = $moduleManager();
        return $ims.$valdiators.alreadyInitialized();
    }

    /////////////////////////////////////////////////////
    //  Manage Validators
    ////////////////////////////////////////////////////
    function _installValidator(
        address validator,
        bytes calldata data
    ) internal virtual {
        SentinelListLib.SentinelList storage $valdiators = $moduleManager()
            .$valdiators;
        $valdiators.push(validator);
        IValidator(validator).onInstall(data);
    }

    function _uninstallValidator(
        address validator,
        bytes calldata data
    ) internal {
        // TODO: check if its the last validator. this might brick the account
        SentinelListLib.SentinelList storage $valdiators = $moduleManager()
            .$valdiators;
        (address prev, bytes memory disableModuleData) = abi.decode(
            data,
            (address, bytes)
        );
        $valdiators.pop(prev, validator);
        IValidator(validator).onUninstall(disableModuleData);
    }

    function _isValidatorInstalled(
        address validator
    ) internal view virtual returns (bool) {
        SentinelListLib.SentinelList storage $valdiators = $moduleManager()
            .$valdiators;
        return $valdiators.contains(validator);
    }

    /**
     * THIS IS NOT PART OF THE STANDARD
     * Helper Function to access linked list
     */
    function getValidatorPaginated(
        address cursor,
        uint256 size
    ) external view virtual returns (address[] memory array, address next) {
        SentinelListLib.SentinelList storage $valdiators = $moduleManager()
            .$valdiators;
        return $valdiators.getEntriesPaginated(cursor, size);
    }

    /////////////////////////////////////////////////////
    //  Manage Executors
    ////////////////////////////////////////////////////

    function _installExecutor(address executor, bytes calldata data) internal {
        SentinelListLib.SentinelList storage $executors = $moduleManager()
            .$executors;
        $executors.push(executor);
        IExecutor(executor).onInstall(data);
    }

    function _uninstallExecutor(
        address executor,
        bytes calldata data
    ) internal {
        SentinelListLib.SentinelList storage $executors = $moduleManager()
            .$executors;
        (address prev, bytes memory disableModuleData) = abi.decode(
            data,
            (address, bytes)
        );
        $executors.pop(prev, executor);
        IExecutor(executor).onUninstall(disableModuleData);
    }

    function _isExecutorInstalled(
        address executor
    ) internal view virtual returns (bool) {
        SentinelListLib.SentinelList storage $executors = $moduleManager()
            .$executors;
        return $executors.contains(executor);
    }

    /**
     * THIS IS NOT PART OF THE STANDARD
     * Helper Function to access linked list
     */
    function getExecutorsPaginated(
        address cursor,
        uint256 size
    ) external view virtual returns (address[] memory array, address next) {
        SentinelListLib.SentinelList storage $executors = $moduleManager()
            .$executors;
        return $executors.getEntriesPaginated(cursor, size);
    }
}
