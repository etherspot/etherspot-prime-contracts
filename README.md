# Etherspot Prime Contracts

[![NPM version][npm-image]][npm-url]
![MIT licensed][license-image]

## Installation & Setup

1. Initalize submodule and update  
`git submodule init && git submodule update`
2. Install dependencies  
`npm i`
3. Install submodule dependencies and compile  
`cd account-abstraction && yarn && npx hardhat compile`

## Contract Deployments

### Prerequisites

Set up your `.env` file following the example found in `.env.example`.

### Etherspot Wallet Factory deployment

`npx hardhat deploy --network <NETWORK_NAME> --tags 'etherspot-wallet-factory'`

### Etherspot Paymaster deployment

`npx hardhat deploy --network <NETWORK_NAME> --tags 'etherspot-paymaster'`

### Etherspot Wallet Factory & Etherspot Paymaster deployment

`npx hardhat deploy --network <NETWORK_NAME> --tags 'required'`

## Test Suite

`npx hardhat test`

### Solidity Usage

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@etherspot/prime-contracts/src/wallet/EtherspotWallet.sol";

// ...
```

## License

MIT

[npm-image]: https://badge.fury.io/js/%40etherspot%2Flite-contracts.svg
[npm-url]: https://npmjs.org/package/@etherspot/lite-contracts
[license-image]: https://img.shields.io/badge/license-MIT-blue.svg
