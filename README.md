# Etherspot Prime Contracts

[![NPM version][npm-image]][npm-url]
![MIT licensed][license-image]

## How to run this repo


1. `git submodule init && git submodule update`
2. `npm i`
3. `cd account-abstraction && yarn && npx hardhat compile`
4. `cd ..`
5. `npx hardhat test`

## Installation

```bash
import "@etherspot/prime-contracts/src/wallet/EtherspotWallet.sol";
```

## Usage

### Solidity

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
