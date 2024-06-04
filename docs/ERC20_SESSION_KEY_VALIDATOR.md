## ERC20SessionKeyValidator

The `ERC20SessionKeyValidator` is a Solidity smart contract that implements the `IValidator` interface from the `IERC7579Module` contract. It is designed to validate user operations (UserOps) for ERC20 token transfers and approvals based on pre-configured session keys.

### Features

- Allows wallet owners to enable and disable session keys for specific ERC20 tokens.
- Supports setting spending limits, validity periods, and pausability for each session key.
- Validates UserOps against the configured session key parameters before execution.
- Provides functions to manage session keys, including rotation and pause/unpause.
- Implements EIP-712 for signature verification.

### Events

- `ERC20SKV_ModuleInstalled(address wallet)`: Emitted when the module is installed.
- `ERC20SKV_ModuleUninstalled(address wallet)`: Emitted when the module is uninstalled.
- `ERC20SKV_SessionKeyEnabled(address sessionKey, address wallet)`: Emitted when a new session key is enabled for a wallet.
- `ERC20SKV_SessionKeyDisabled(address sessionKey, address wallet)`: Emitted when a session key is disabled for a wallet.
- `ERC20SKV_SessionKeyPaused(address sessionKey, address wallet)`: Emitted when a session key is paused.
- `ERC20SKV_SessionKeyUnpaused(address sessionKey, address wallet)`: Emitted when a session key is unpaused.

### Errors

- `ERC20SKV_ModuleAlreadyInstalled()`: Thrown when the module is already installed.
- `ERC20SKV_ModuleNotInstalled()`: Thrown when the module is not installed.
- `ERC20SKV_InvalidSessionKey()`: Thrown when the provided session key is invalid or expired.
- `ERC20SKV_InvalidToken()`: Thrown when the provided token address is invalid >> `address(0)` check.
- `ERC20SKV_InvalidInterfaceId()`: Thrown when the provided interface ID is invalid >>  `bytes(0)` check.
- `ERC20SKV_InvalidFunctionSelector()`: Thrown when the provided function selector is invalid >>  `bytes(0)` check.
- `ERC20SKV_InvalidSpendingLimit()`: Thrown when the provided spend limit for the session key is zero.
- `ERC20SKV_InvalidDuration(uint256 validAfter, uint256 validUntil)`: Thrown when the provided `validUntil` and `validAfter` are zero or when the `validUntil` is less than the `validAfter`.
- `ERC20SKV_SessionKeyAlreadyExists(address sessionKey)`: Thrown when the provided session key already exists.
- `ERC20SKV_SessionKeyDoesNotExist(address session)`: Thrown when the provided session key does not exist.
- `ERC20SKV_SessionPaused(address sessionKey)`: Thrown when the provided session key is currently paused.
- `ERC20SKV_UnsuportedToken()`: Thrown when the target contract is not the configured token for the session key.
- `ERC20SKV_UnsupportedInterface()`: Thrown when the target contract does not support the required interface for the session key.
- `ERC20SKV_UnsupportedSelector(bytes4 selectorUsed)`: Thrown when the function selector is not supported by the session key.
- `ERC20SKV_SessionKeySpendLimitExceeded()`: Thrown when the requested transfer amount exceeds the spending limit of the session key.
- `NotImplemented()`: Thrown for unimplemented functions.

### Structs

- `SessionData`: Stores the configuration data for a session key, including the token address, interface ID, function selector, spending limit, validity period, and pause status.

### Functions

- `enableSessionKey(bytes calldata _sessionData)`: Enables a new session key for the caller's wallet with the provided configuration data.
- `disableSessionKey(address _session)`: Disables the specified session key for the caller's wallet.
- `rotateSessionKey(address _oldSessionKey, bytes calldata _newSessionData)`: Disables the old session key and enables a new one with the provided configuration data.
- `toggleSessionKeyPause(address _sessionKey)`: Toggles the pause status of the specified session key for the caller's wallet.
- `checkSessionKeyPaused(address _sessionKey)`: Checks if the specified session key is currently paused for the caller's wallet.
- `validateSessionKeyParams(address _sessionKey, PackedUserOperation calldata userOp)`: Validates the provided UserOp against the configuration of the specified session key.
- `getAssociatedSessionKeys()`: Returns an array of session keys associated with the caller's wallet.
- `getSessionKeyData(address _sessionKey)`: Returns the configuration data for the specified session key and the caller's wallet.
- `validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)`: Validates the provided UserOp using the EIP-712 signature and session key parameters.
- `isModuleType(uint256 moduleTypeId)`: Checks if the contract is a validator module type.
- `onInstall(bytes calldata data)`: Required by the `IValidator` interface but not implemented.
- `onUninstall(bytes calldata data)`: Required by the `IValidator` interface but not implemented.
- `isValidSignatureWithSender(address sender, bytes32 hash, bytes calldata data)`: Required by the `IValidator` interface but not implemented.
- `isInitialized(address smartAccount)`: Required by the `IValidator` interface but not implemented.

### Internal Functions

- `_digest(bytes calldata _data)`: Internal function that extracts the function selector, target contract, recipient, sender, and amount from the provided calldata.
- `_domainSeparator()`: Internal function that calculates the EIP-712 domain separator for signature verification.
- `_domainNameAndVersion()`: Internal function that returns the contract name and version for the EIP-712 domain separator.

### Usage

To use the `ERC20SessionKeyValidator` contract, wallet owners can enable session keys with specific configurations for ERC20 token transfers and approvals. The contract will validate UserOps against the configured session key parameters before execution, ensuring that the requested operation is within the allowed limits and validity period.
