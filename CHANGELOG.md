# Changelog

## [3.0.0] - 2025-01-10

### Breaking Changes

- Updated deterministic contract addresses for:
  - `ModularEtherspotWallet`
  - `ModularEtherspotWalletFactory`
  - `Bootstrap`
  - `MultipleOwnerECDSAValidator`
- Redeployed contracts on all supported networks with new addresses.

### Added

- Added `bytecodeHash = "none"` to foundry.toml to stop appending bytecode hash for deployments.
- Added new `DeployAllAndSetupScript` script to deploy all contracts and to stake `ModularEtherspotWalletFactory` with the `EntryPoint` contract.
- Added new deployment scripts for individual contract deployments.

### Changed

- Updated deployment scripts to use new deterministic contract addresses.

### Removed

- Removed `StakeModularWalletFactoryScript` script due to duplication.