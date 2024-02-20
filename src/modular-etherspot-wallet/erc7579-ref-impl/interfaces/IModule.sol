// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC4337.sol";

uint256 constant VALIDATION_SUCCESS = 0;
uint256 constant VALIDATION_FAILED = 1;

interface IModule {
    /**
     * Enable module
     *  This function is called by the MSA during "installValidator, installExecutor, installHook"
     * @dev this function MUST revert on error (i.e. if module is already enabled)
     */
    function onInstall(bytes calldata data) external;

    /**
     * Disable module
     *  This function is called by the MSA during "uninstallValidator, uninstallExecutor, uninstallHook"
     * @dev this function MUST deinitialize the module for the user, so that it can be re-enabled later
     */
    function onUninstall(bytes calldata data) external;

    /**
     * @dev Returns boolean value if Module is a certain ERC7579 Type
     */
    function isModuleType(uint256 typeID) external view returns (bool);
}

interface IValidator is IModule {
    error InvalidExecution(bytes4 functionSig);
    error InvalidTargetAddress(address target);
    error InvalidTargetCall();

    /**
     * @dev Validates a transaction on behalf of the account.
     *         This function is intended to be called by the MSA during the ERC-4337 validaton phase
     *         Note: solely relying on bytes32 hash and signature is not suffcient for some validation implementations (i.e. SessionKeys often need access to userOp.calldata)
     * @param userOp The user operation to be validated. The userOp MUST NOT contain any metadata. The MSA MUST clean up the userOp before sending it to the validator.
     * @param userOpHash The hash of the user operation to be validated
     * @return return value according to ERC-4337
     */
    function validateUserOp(
        IERC4337.UserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256);

    /**
     * Validator can be used for ERC-1271 validation
     */
    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4);
}

interface IExecutor is IModule {}

interface IHook is IModule {
    function preCheck(
        address msgSender,
        bytes calldata msgData
    ) external returns (bytes memory hookData);
    function postCheck(bytes calldata hookData) external returns (bool success);
}

interface IFallback is IModule {}
