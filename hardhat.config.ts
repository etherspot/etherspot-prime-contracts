import * as dotenv from 'dotenv';
import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@openzeppelin/hardhat-upgrades';
import 'hardhat-deploy';
import 'hardhat-exposed';

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
      url: 'https://arbitrum-one.publicnode.com',
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
    gnosis: {
      chainId: 100,
      url: 'https://rpc.ankr.com/gnosis',
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
      chainId: 420,
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
    baseGoerli: {
      chainId: 84531,
      url: 'https://goerli.base.org',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    chiado: {
      chainId: 10200,
      url: 'https://rpc.chiadochain.net',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      initialBaseFeePerGas: 7,
    },
    rskt: {
      chainId: 31,
      url: 'https://public-node.testnet.rsk.co',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    rskm: {
      chainId: 30,
      url: 'https://public-node.rsk.co',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    kroma: {
      chainId: 2357,
      url: 'https://api.sepolia.kroma.network/',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    taikot: {
      chainId: 167005,
      url: 'https://rpc.test.taiko.xyz',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    verse: {
      chainId: 20197,
      url: 'https://rpc.sandverse.oasys.games',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    mantle: {
      chainId: 5000,
      url: 'https://rpc.mantle.xyz',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    bifrostTest: {
      chainId: 49088,
      url: 'https://public-01.testnet.thebifrost.io/rpc',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    bifrost: {
      chainId: 3068,
      url: 'https://public-01.mainnet.thebifrost.io/rpc',
    klaytnTest: {
      chainId: 1001,
      url: 'https://public-en-baobab.klaytn.net',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    klaytn: {
      chainId: 8217,
      url: 'https://public-node-api.klaytnapi.com/v1/cypress',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    dev: { url: 'http://localhost:8545' },
  },
  deterministicDeployment: {
    [49088]: {
      factory: '0x20F697b303481445Cb84ad836c8336634E7b53ad',
      deployer: '0xE1CB04A0fA36DdD16a06ea828007E35e1a3cBC37',
      funding: '10000000000000000',
      signedTx:
        '0xf8a88085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3830150f6a032b2a806bfc34024c6638848c3798213261304af82de14002ca2b4961a643b95a03c74c13eda5ff6b9b821fbccd1a67f160eb6a0ca50dad04b7a3e564e2599722e',
    },
    [3068]: {
      factory: '0x74981a89B74bC6bed15Db203Fa6B6c16A8877aE4',
      deployer: '0xE1CB04A0fA36DdD16a06ea828007E35e1a3cBC37',
      funding: '10000000000000000',
      signedTx:
        '0xf8a88085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3830150f6a032b2a806bfc34024c6638848c3798213261304af82de14002ca2b4961a643b95a03c74c13eda5ff6b9b821fbccd1a67f160eb6a0ca50dad04b7a3e564e2599722e',
    },
  },
  mocha: {
    timeout: 10000,
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY!,
      arbitrumOne: process.env.ARBISCAN_API_KEY!,
      optimisticEthereum: process.env.OPTIMISM_EXPLORER_API_KEY!,
      polygon: process.env.POLYSCAN_API_KEY!,
      fuse: process.env.FUSE_EXPLORER_API_KEY!,
      gnosis: process.env.GNOSISSCAN_API_KEY!,
      mantle: process.env.BASEGOERLI_BLOCKSCOUT_API_KEY!, // works with same key
      ////////////////////////////////////
      goerli: process.env.ETHERSCAN_API_KEY!,
      sepolia: process.env.ETHERSCAN_API_KEY!,
      arbitrumGoerli: process.env.ARBISCAN_API_KEY!,
      optimisticGoerli: process.env.OPTIMISM_EXPLORER_API_KEY!,
      polygonMumbai: process.env.POLYSCAN_API_KEY!,
      fuseSparknet: process.env.FUSE_EXPLORER_API_KEY!,
      baseGoerli: process.env.BASEGOERLI_BLOCKSCOUT_API_KEY!,
      chiado: process.env.CHIADO_EXPLORER_API_KEY!,
      kroma: '', // not yet available
      taikot: '', // not yet available
      verse: process.env.BASEGOERLI_BLOCKSCOUT_API_KEY!, // works with same key
    },
    customChains: [
      {
        network: 'baseGoerli',
        chainId: 84531,
        urls: {
          apiURL: 'https://base-goerli.blockscout.com/api',
          browserURL: 'https://base-goerli.blockscout.com/',
        },
      },
      {
        network: 'fuse',
        chainId: 122,
        urls: {
          apiURL: 'https://explorer.fuse.io/api',
          browserURL: 'https://explorer.fuse.io/',
        },
      },
      {
        network: 'fuseSparknet',
        chainId: 123,
        urls: {
          apiURL: 'https://explorer.fusespark.io/api',
          browserURL: 'https://explorer.fusespark.io/',
        },
      },
      {
        network: 'chiado',
        chainId: 10200,
        urls: {
          apiURL: 'https://gnosis-chiado.blockscout.com/api',
          browserURL: 'https://gnosis-chiado.blockscout.com/',
        },
      },
      {
        network: 'kroma',
        chainId: 2357,
        urls: {
          apiURL: 'https://blockscout.sepolia.kroma.network/api',
          browserURL: 'https://blockscout.sepolia.kroma.network/',
        },
      },
      {
        network: 'taikot',
        chainId: 167005,
        urls: {
          apiURL: 'https://explorer.test.taiko.xyz/api',
          browserURL: 'https://explorer.test.taiko.xyz/',
        },
      },
      {
        network: 'verse',
        chainId: 20197,
        urls: {
          apiURL: 'https://scan.sandverse.oasys.games/api',
          browserURL: 'https://scan.sandverse.oasys.games/',
        },
      },
      {
        network: 'mantle',
        chainId: 5000,
        urls: {
          apiURL: 'https://explorer.mantle.xyz/api',
          browserURL: 'https://explorer.mantle.xyz/',
        },
      },
      {
        network: 'bifrostTest',
        chainId: 49088,
        urls: {
          apiURL: 'https://public-01.testnet.thebifrost.io/rpc',
          browserURL: '',
        },
      },
      {
        network: 'bifrost',
        chainId: 3068,
        urls: {
          apiURL: 'https://public-01.mainnet.thebifrost.io/rpc',
          browserURL: '',
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
