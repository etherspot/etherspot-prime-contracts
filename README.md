# Etherspot Prime Contracts

[![NPM version][npm-image]][npm-url]
![MIT licensed][license-image]

Smart contract infrastructure for Etherspot Prime, supporting the ERC4337 implementation.

## Installation & Setup

`npm run setup`

## Contract Deployments

### Prerequisites

Set up your `.env` file following the example found in `.env.example`.

### Etherspot Wallet Factory deployment

`npx hardhat deploy --network <NETWORK_NAME> --tags 'etherspot-wallet-factory'`

### Etherspot Paymaster deployment

`npx hardhat deploy --network <NETWORK_NAME> --tags 'etherspot-paymaster'`

### Etherspot Wallet Factory & Etherspot Paymaster deployment

`npx hardhat deploy --network <NETWORK_NAME> --tags 'required'`

### Test Suite

`npx hardhat test`

### Solidity Usage

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@etherspot/prime-contracts/src/etherspot-wallet-v1/wallet/EtherspotWallet.sol";

// ...
```

## Documentation

- [ERC4337 Specification](https://eips.ethereum.org/EIPS/eip-4337)
- [Integration Guide](https://docs.etherspot.dev)

## License

MIT

[npm-image]: https://badge.fury.io/js/%40etherspot%2Flite-contracts.svg
[npm-url]: https://npmjs.org/package/@etherspot/lite-contracts
[license-image]: https://img.shields.io/badge/license-MIT-blue.svg
