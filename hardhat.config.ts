import * as dotenv from 'dotenv';
import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-chai-matchers';
import '@nomiclabs/hardhat-etherscan';
import '@typechain/hardhat';
import '@openzeppelin/hardhat-upgrades';
import 'hardhat-deploy';
import 'hardhat-gas-reporter';
import 'hardhat-tracer';
import 'hardhat-exposed';
import 'solidity-coverage';
import 'xdeployer';

dotenv.config({ path: __dirname + '/.env' });

const config: HardhatUserConfig = {
  namedAccounts: {
    from: 0,
  },
  solidity: {
    compilers: [
      {
        version: '0.8.12',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      // allowUnlimitedContractSize: true,
    },
    mainnet: {
      chainId: 1,
      url: 'https://rpc.ankr.com/eth',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    arbitrum: {
      chainId: 42161,
      url: 'https://rpc.ankr.com/arbitrum',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    optimism: {
      chainId: 10,
      url: 'https://rpc.ankr.com/optimism',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    polygon: {
      chainId: 137,
      url: 'https://rpc.ankr.com/polygon',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    fuse: {
      chainId: 122,
      url: 'https://rpc.fuse.io',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    goerli: {
      chainId: 5,
      url: 'https://rpc.ankr.com/eth_goerli',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    sepolia: {
      chainId: 11155111,
      url: 'https://rpc.sepolia.org',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    arbitrumGoerli: {
      chainId: 421613,
      url: 'https://goerli-rollup.arbitrum.io/rpc',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    optimismGoerli: {
      chainId: 80001,
      url: 'https://goerli.optimism.io',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    mumbai: {
      chainId: 80001,
      url: 'https://rpc.ankr.com/polygon_mumbai',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    fuseSparknet: {
      chainId: 123,
      url: 'https://rpc.fusespark.io',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    dev: { url: 'http://localhost:8545' },
  },
  mocha: {
    timeout: 10000,
  },
  etherscan: {
    apiKey: {
      mumbai: process.env.POLYSCAN_API_KEY!,
    },
    customChains: [
      {
        network: 'mumbai',
        chainId: 80001,
        urls: {
          apiURL: 'https://api-testnet.polygonscan.com/api',
          browserURL: 'https://mumbai.polygonscan.com/',
        },
      },
    ],
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    token: 'MATIC',
    coinmarketcap: 'd574b328-92e4-40d5-87ef-c2d99aa38bc0',
    gasPriceApi:
      'https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice',
  },
  paths: {
    sources: './src',
    cache: '.hardhat/cache',
    artifacts: './artifacts',
    deploy: './deploy',
    deployments: './deployments',
  },
  typechain: {
    outDir: 'typings',
  },
};

export default config;
