import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-preprocessor';
import '@nomicfoundation/hardhat-chai-matchers';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-waffle';
import 'hardhat-deploy';
import '@nomiclabs/hardhat-etherscan';
import 'solidity-coverage';
import 'hardhat-tracer';
import 'hardhat-exposed';
import '@openzeppelin/hardhat-upgrades';
import fs from 'fs';
const { resolve } = require('path');
const { config: dotenvConfig } = require('dotenv');

dotenvConfig({ path: resolve(__dirname, './.env') });

function getRemappings() {
  return fs
    .readFileSync('remappings.txt', 'utf8')
    .split('\n')
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split('='));
}

const config: HardhatUserConfig = {
  solidity: '0.8.12',
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    mumbai: {
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.MUMBAI_ALCHEMY_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
    dev: { url: 'http://localhost:8545' },
  },
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          for (const [from, to] of getRemappings()) {
            if (line.includes(from)) {
              line = line.replace(from, to);
              break;
            }
          }
        }
        return line;
      },
    }),
  },
  mocha: {
    timeout: 10000,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  paths: {
    sources: './src',
    cache: './cache_hardhat',
    artifacts: './artifacts',
  },
  typechain: {
    outDir: 'typings',
  },
};

export default config;
