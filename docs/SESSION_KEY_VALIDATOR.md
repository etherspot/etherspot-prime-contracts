# SessionKeyValidator Contract Documentation

## Overview

The `SessionKeyValidator` is a Solidity smart contract that implements the `ISessionKeyValidator` interface and is designed to work with ERC-7579 compatible wallets. It enables the creation and management of session keys with granular permissions, allowing for secure and flexible wallet interactions.

## Features

- Enable, disable, and rotate session keys for specific wallets
- Set and manage permissions for each session key, including target contracts, function selectors, payableLimits, uses and specific parameter conditions.
- Validate user operations (UserOps) against configured session key parameters
- Support for both single and batch executions
- Pause/unpause functionality for session keys

## Events

- `SKV_ModuleInstalled(address wallet)`
- `SKV_ModuleUninstalled(address wallet)`
- `SKV_SessionKeyEnabled(address indexed sessionKey, address indexed wallet)`
- `SKV_SessionKeyDisabled(address indexed sessionKey, address indexed wallet)`
- `SKV_SessionKeyPauseToggled(address indexed sessionKey, address indexed wallet, bool newStatus)`
- `SKV_PermissionUsesUpdated(address indexed sessionKey, uint256 index, uint256 previousUses, uint256 newUses)`
- `SKV_SessionKeyValidUntilUpdated(address indexed sessionKey, address indexed wallet, uint48 newValidUntil)`
- `SKV_PermissionAdded(address indexed sessionKey, address indexed wallet, address target, bytes4 selector, uint256 payableLimit, uint256 uses, ParamCondition[] paramConditions)`
- `SKV_PermissionModified(address indexed sessionKey, address indexed wallet, uint256 index, address target, bytes4 selector, uint256 payableLimit, uint256 uses, ParamCondition[] paramConditions)`
- `SKV_PermissionRemoved(address indexed sessionKey, address indexed wallet, uint256 indexToRemove)`

## Errors

- `SKV_ModuleAlreadyInstalled()`
- `SKV_ModuleNotInstalled()`
- `SKV_InvalidSessionKeyData(address sessionKey, uint48 validAfter, uint48 validUntil)`
- `SKV_InvalidPermissionData(address sessionKey, address target, bytes4 selector, uint256 payableLimit, uint256 uses, ParamCondition[] conditions)`
- `SKV_InvalidPermissionIndex()`
- `SKV_SessionKeyAlreadyExists(address sessionKey)`
- `SKV_SessionKeyDoesNotExist(address sessionKey)`
- `NotImplemented()`

## Structs

### SessionKeyData

Stores all the information related to a specific session key.
A wallet can have multiple session keys.

```solidity
struct SessionData {
    uint48 validAfter;
    uint48 validUntil;
    bool live;
}
```

### Permission

Defines the specific permissions granted to a session key.
A Session Key can have multiple permissions, each with a different target contract, function selector, payable call limit, uses and function parameter conditions. It is used for validating the UserOperation.

```solidity
struct Permission {
    address target;
    bytes4 selector;
    uint256 payableLimit;
    uint256 uses;
    ParamCondition[] paramConditions;
}
```

### ParamCondition

Defines the conditions that must be met for a specific function parameter.

```solidity
struct ParamCondition {
    uint256 offset;
    ComparisonRule rule;
    bytes32 value;
}
```

### ExecutionData

Used to represent the validity period of a specific execution.
This data is encoded in the signature of a UserOperation.
It is used to help with validation and execution.
When a user signs a UserOperation using a session key, they include one or more ExecutionData structures in the signature depending on the number of executions.

```solidity
struct ExecutionData {
    uint48 validAfter;
    uint48 validUntil;
}
```

## Mappings

`walletSessionKeys`

Maps a wallet address to its associated session keys.

```solidity
mapping(address wallet => address[] sessionKeys) public walletSessionKeys;
```

`sessionData`

Maps a session key to its associated SessionData.

```solidity
mapping(address sessionKey => mapping(address wallet => SessionData)) public sessionData;
```

`permissions`

Maps a session key to its associated permissions.

```solidity
 mapping(address sessionKey => mapping(address wallet => Permission[])) public permissions;
 ```

 
## External/Public Functions

### Session Key Management

`enableSessionKey`

Enables a new session key with specified permissions.

```solidity
function enableSessionKey(SessionData memory _sessionData, Permission[] memory _permissions) public
```

`disableSessionKey`

Disables an existing session key.

```solidity
function disableSessionKey(address _session) public
```

`rotateSessionKey`

Replaces an old session key with a new one.

```solidity
function rotateSessionKey(address _oldSessionKey, bytes calldata _newSessionData) external
```

`toggleSessionKeyPause`

Toggles the live state of a session key.

```solidity
function toggleSessionKeyPause(address _sessionKey) external
```

`updateValidUntil` 

Updates the validUntil timestamp for a session key.

```solidity
function updateValidUntil(address _sessionKey, uint48 _newValidUntil) public
```

### Permission Management

`addPermission`

Adds a new permission to a session key.

```solidity
function addPermission(address _sessionKey, Permission memory _permission) public
```

`removePermission`

Removes a permission from a session key.

```solidity
function removePermission(address _sessionKey, uint256 _permissionIndex) public
```

`modifyPermission`

Modifies an existing permission for a session key. It allows for modifying partial or complete permissions. Passing in empty values will not modify that field.

```solidity
function modifyPermission(address _sessionKey, uint256 _index, address _target, bytes4 _selector, uint256 _payableLimit_, uint256 _uses, ParamCondition[] calldata _paramConditions) public
```

`updateUses`

Updates the number of uses for a specific permission.

```solidity
function updateUses(address _sessionKey, uint256 _permissionIndex, uint256 _newUses) external
```

### Validation

`validateUserOp`

Validates a UserOperation.

```solidity
function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external override returns (uint256)
```

### Utility Functions

`getSessionKeysByWallet`

Returns all session keys associated with the caller's wallet.

```solidity
function getSessionKeysByWallet() public view returns (address[] memory)
```

`getSessionKeyData`

Returns the data associated with a specific session key.

```solidity
function getSessionKeyData(address _sessionKey) public view returns (SessionData memory)
```

`getSessionKeyPermissions`

Returns the permissions associated with a specific session key.

```solidity
function getSessionKeyPermissions(address _sessionKey) public view returns (Permission[] memory)
```

`isSessionKeyLive`

Returns the live status of a session key.

```solidity
function isSessionLive(address _sessionKey) public view returns (bool)
```

`getUsesLeft`

Returns the number of uses left for a specific permission.

```solidity
function getUsesLeft(address _sessionKey, uint256 _permissionIndex) public view returns (uint256)
```


## Internal Functions

`_validateSessionKeyParams`

Validates session key parameters for a given user operation.

```solidity
function _validateSessionKeyParams(address _sessionKey, PackedUserOperation calldata _userOp, ExecutionData[] memory _execVals) internal view returns (bool success, uint48 validAfter, uint48 validUntil)
```

`_validateSingleExecution`

Validates a single execution against session key permissions.

```solidity
function _validateSingleExecution(PackedUserOperation calldata _userOp, SessionData memory _sd, ExecutionValidation memory _execVal) internal pure returns (bool, uint48, uint48)
```

`_validateBatchExecution`

Validates a batch execution against session key permissions.

```solidity
function _validateBatchExecution(PackedUserOperation calldata _userOp, SessionData memory _sd, ExecutionValidation[] memory _execVals) internal pure returns (bool, uint48, uint48)
```

`_validatePermission`

Validates if a given execution is permitted based on the session data and permissions.

```solidity
function _validatePermission(address _sender, SessionData memory _sd, ExecutionValidation memory _execVal, address target, uint256 value, bytes calldata callData) internal pure returns (bool)
```

`_extractExecutionValidationAndSignature`

Extracts ExecutionValidation and signature from UserOperation signature.

```solidity
function _extractExecutionValidationAndSignature(bytes calldata _userOpSig) internal pure returns (ExecutionValidation[] memory execVals, bytes32 r, bytes32 s, uint8 v)
```

## Testing

To run the tests, use the following command:

```bash
forge test --match-contract "SessionKeyValidator" --no-match-contract "ERC20" -vvv
```

### Test Coverage

| File                                                                             | % Lines           | % Statements      | % Branches       | % Funcs          |
|----------------------------------------------------------------------------------|-------------------|-------------------|------------------|------------------|
| src/modular-etherspot-wallet/modules/validators/SessionKeyValidator.sol          | 100.00% (183/183) | 99.24% (261/263)  | 90.91% (80/88)   | 100.00% (26/26)  |

### Test Results

Ran 72 tests for test/foundry/modules/SessionKeyValidator/concrete/SessionKeyValidator.t.sol:SessionKeyValidator_Concrete_Test  
[PASS] test_addPermission()  
[PASS] test_addPermission_RevertIf_InvalidTarget()  
[PASS] test_addPermission_RevertIf_SessionKeyDoesNotExist()  
[PASS] test_batchExecutionERC20()  
[PASS] test_disableSessionKey()  
[PASS] test_disableSessionKey_RevertIf_NonExistentSessionKey()  
[PASS] test_disableSessionKey_RevertIf_SessionKeyAlreadyDisabled()  
[PASS] test_enableSessionKey()  
[PASS] test_enableSessionKey_RevertIf_InvalidUsageAmount()  
[PASS] test_enableSessionKey_RevertIf_InvalidValidAfter()  
[PASS] test_enableSessionKey_RevertIf_InvalidValidUntil()  
[PASS] test_enableSessionKey_RevertIf_PermissionInvalidTarget()  
[PASS] test_enableSessionKey_RevertIf_SessionKeyAlreadyExists()  
[PASS] test_enableSessionKey_RevertIf_SessionKeyZeroAddress()  
[PASS] test_executeBatch()  
[PASS] test_executeBatch_RevertIf_InvalidFunctionSelector()  
[PASS] test_executeBatch_RevertIf_InvalidTarget()  
[PASS] test_executeBatch_callAndNative()  
[PASS] test_executeBatch_payableCallAndNative()  
[PASS] test_executeSingle()  
[PASS] test_executeSingle_Native()  
[PASS] test_executeSingle_Native_RevertIf_InvalidAmount()  
[PASS] test_executeSingle_RevertIf_InvalidFunctionSelector()  
[PASS] test_executeSingle_RevertIf_InvalidSessionKey()  
[PASS] test_executeSingle_RevertIf_InvalidTarget()  
[PASS] test_executeSingle_RevertIf_NoPermissions()  
[PASS] test_executeSingle_RevertIf_NoUsesLeft()  
[PASS] test_executeSingle_RevertIf_Paused()  
[PASS] test_executeSingle_callPayable()  
[PASS] test_executeSingle_maximumUsesForPermissionExceeded()  
[PASS] test_exposed_checkCondition_testEqualCondition()  
[PASS] test_exposed_checkCondition_testGreaterThanCondition()  
[PASS] test_exposed_checkCondition_testGreaterThanOrEqualCondition()  
[PASS] test_exposed_checkCondition_testLessThanCondition()  
[PASS] test_exposed_checkCondition_testLessThanOrEqualCondition()  
[PASS] test_exposed_checkCondition_testNotEqualCondition()  
[PASS] test_exposed_extractExecutionValidationAndSignature()  
[PASS] test_exposed_validatePermission()  
[PASS] test_exposed_validateSessionKeyParams()  
[PASS] test_exposed_validateSessionKeyParams_InvalidCallType()  
[PASS] test_getSessionKeyByWallet_returnEmptyForWalletWithNoSessionKeys()  
[PASS] test_getSessionKeyData_RevertIf_SessionKeyDoesNotExist()  
[PASS] test_getSessionKeyData_and_getSessionKeyPermissions()  
[PASS] test_getSessionKeyPermissions_RevertIf_SessionKeyDoesNotExist()  
[PASS] test_getSessionKeysByWallet()  
[PASS] test_getUsesLeft_and_updateUses()  
[PASS] test_installModule()  
[PASS] test_installModule_cantDoubleInstall()  
[PASS] test_isInitialized()  
[PASS] test_isModuleType()  
[PASS] test_isValidSignatureWithSender()  
[PASS] test_modifyPermission()  
[PASS] test_modifyPermission_InvalidIndex()  
[PASS] test_modifyPermission_NonExistentSessionKey()  
[PASS] test_modifyPermission_PartialUpdate()  
[PASS] test_removePermission()  
[PASS] test_removePermission_RemoveLastPermission()  
[PASS] test_removePermission_RevertIf_InvalidPermissionIndex()  
[PASS] test_removePermission_RevertIf_SessionKeyDoesNotExist()  
[PASS] test_rotateSessionKey()  
[PASS] test_rotateSessionKey_RevertIf_NonExistantSessionKey()  
[PASS] test_toggleSessionKeyPause_RevertIf_SessionKeyDoesNotExist()  
[PASS] test_toggleSessionKeyPause_and_isSessionLive()  
[PASS] test_uninstallModule()  
[PASS] test_uninstallModule_cantUninstallIfNotInstalled()  
[PASS] test_updateUses_RevertIf_InvaildSessionKey()  
[PASS] test_updateValidUntil()  
[PASS] test_updateValidUntil_MultipleTimes()  
[PASS] test_updateValidUntil_RevertIf_SessionKeyDoesNotExist()  
[PASS] test_validateUserOp_RevertIf_InvalidSigner()  
[PASS] test_validateUserOp_RevertIf_SessionKeyExpired()  
[PASS] test_validateUserOp_RevertIf_SessionKeyNotYetActive()  
Suite result: ok. 72 passed; 0 failed; 0 skipped; finished in 302.63ms (296.83ms CPU time)

Ran 14 tests for test/foundry/modules/SessionKeyValidator/fuzz/SessionKeyValidator.t.sol:SessionKeyValidator_Fuzz_Test  
[PASS] testFuzz_addPermission(address,bytes4,uint256,uint256,uint8,bytes32)  
[PASS] testFuzz_enableSessionKey(uint48,uint48,uint256,address,bytes4,uint256,uint256,bytes32)  
[PASS] testFuzz_executeBatch(address,uint256,bool,uint256)  
[PASS] testFuzz_executeSingle(address,uint256,bool)  
[PASS] testFuzz_executeSingle_Native(uint256,uint256)  
[PASS] testFuzz_getSessionKeyPermissions(uint8)  
[PASS] testFuzz_getSessionKeysByWallet(uint8)  
[PASS] testFuzz_modifyPermission(address,bytes4,uint256,uint256,uint8,uint8,bytes32)  
[PASS] testFuzz_modifyPermission_completeAndPartialModification(address,bytes4,uint256,uint256,uint8,uint8,bytes32,uint8)  
[PASS] testFuzz_removePermission(uint8)  
[PASS] testFuzz_rotateSessionKey(address,uint48,uint48,bool,uint256,uint256)  
[PASS] testFuzz_toggleSessionKeyPause(uint8)  
[PASS] testFuzz_updateUses(uint256)  
[PASS] testFuzz_updateValidUntil(uint48,uint48)  
Suite result: ok. 14 passed; 0 failed; 0 skipped; finished in 3.34s (20.71s CPU time)
