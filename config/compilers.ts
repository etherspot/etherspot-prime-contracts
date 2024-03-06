import { HardhatUserConfig } from 'hardhat/config';

const compilers: HardhatUserConfig['solidity'] = {
  compilers: [
    {
      version: '0.8.12',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: 'london',
      },
    },
    {
      version: '0.8.17',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: 'london',
      },
    },
    {
      version: '0.8.21',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: 'london',
      },
    },
    {
      version: '0.8.23',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: 'london',
      },
    },
  ],
};

export default compilers;
