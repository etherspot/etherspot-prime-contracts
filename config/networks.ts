import * as dotenv from 'dotenv';
import { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

const networks: HardhatUserConfig['networks'] = {
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
    url: 'https://eth-sepolia.public.blastapi.io',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  arbitrumGoerli: {
    chainId: 421613,
    url: 'https://goerli-rollup.arbitrum.io/rpc',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  optimismGoerli: {
    chainId: 420,
    url: 'https://optimism-goerli.publicnode.com',
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
  kromaSepolia: {
    chainId: 2358,
    url: 'https://api.sepolia.kroma.network',
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
  mantleTestnet: {
    chainId: 5001,
    url: 'https://rpc.testnet.mantle.xyz',
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
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
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
  avalanche: {
    chainId: 43114,
    url: 'https://avalanche-c-chain.publicnode.com',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  fuji: {
    chainId: 43113,
    url: 'https://avalanche-fuji-c-chain.publicnode.com',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  bsc: {
    chainId: 56,
    url: 'https://bsc.publicnode.com',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  bscTestnet: {
    chainId: 97,
    url: 'https://bsc-testnet.publicnode.com',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  base: {
    chainId: 8453,
    url: 'https://base.publicnode.com',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  linea: {
    chainId: 59144,
    url: 'https://linea.blockpi.network/v1/rpc/public',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  lineaTestnet: {
    chainId: 59140,
    url: 'https://rpc.goerli.linea.build',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  scrollSepolia: {
    chainId: 534351,
    url: 'https://sepolia-rpc.scroll.io/',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  coston2: {
    chainId: 114,
    url: 'https://coston2-api.flare.network/ext/C/rpc',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  flare: {
    chainId: 14,
    url: `https://flare-api-tracer.flare.network/ext/C/rpc?auth=${process.env.FLARE_RPC_KEY}`,
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  scroll: {
    chainId: 534352,
    url: 'https://rpc.scroll.io',
    accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
  },
  dev: { url: 'http://localhost:8545' },
};
export default networks;
