# Etherspot Lite Solidity contracts

[![NPM version][npm-image]][npm-url]

## How to run this repo


1. `git submodule init --update`
2. `npm i`
3. `cd account-abstraction && yarn && npx hardhat compile`
4. `npx hardhat test`

## Installation

```bash
$ npm i @etherspot/lite-contracts -S
```

## Usage

### Solidity

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@etherspot/lite-contracts/src/EtherspotWallet.sol";

// ...
```

## License

MIT

[npm-image]: https://badge.fury.io/js/%40etherspot%2Flite-contracts.svg
[npm-url]: https://npmjs.org/package/@etherspot/lite-contracts


