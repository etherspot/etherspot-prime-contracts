import * as dotenv from 'dotenv';
import { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

const etherscan: HardhatUserConfig['etherscan'] = {
  apiKey: {
    mainnet: process.env.ETHERSCAN_API_KEY!,
    arbitrumOne: process.env.ARBISCAN_API_KEY!,
    optimisticEthereum: process.env.OPTIMISM_EXPLORER_API_KEY!,
    polygon: process.env.POLYSCAN_API_KEY!,
    fuse: process.env.FUSE_EXPLORER_API_KEY!,
    gnosis: process.env.GNOSISSCAN_API_KEY!,
    mantle: process.env.BASESCAN_API_KEY!, // works with same key
    avalanche: process.env.AVALANCHE_EXPLORER_API_KEY!,
    bsc: process.env.BSC_EXPLORER_API_KEY!,
    base: process.env.BASESCAN_API_KEY!,
    linea: process.env.LINEASCAN_API_KEY!,
    flare: process.env.FLARESCAN_API_KEY!,
    scroll: process.env.SCROLLSCAN_API_KEY!,
    ////////////////////////////////////
    goerli: process.env.ETHERSCAN_API_KEY!,
    sepolia: process.env.ETHERSCAN_API_KEY!,
    arbitrumGoerli: process.env.ARBISCAN_API_KEY!,
    optimisticGoerli: process.env.OPTIMISM_EXPLORER_API_KEY!,
    polygonMumbai: process.env.POLYSCAN_API_KEY!,
    fuseSparknet: process.env.FUSE_EXPLORER_API_KEY!,
    baseGoerli: process.env.BASESCAN_API_KEY!,
    chiado: process.env.CHIADO_EXPLORER_API_KEY!,
    kromaSepolia: '', // not yet available
    taikot: '', // not yet available
    verse: process.env.BASESCAN_API_KEY!, // works with same key
    avalancheFujiTestnet: process.env.AVALANCHE_EXPLORER_API_KEY!,
    bscTestnet: process.env.BSC_EXPLORER_API_KEY!,
    lineaTestnet: process.env.LINEASCAN_API_KEY!,
    scrollSepolia: process.env.BASEGOERLI_BLOCKSCOUT_API_KEY!,
    mantleTestnet: process.env.BASESCAN_API_KEY!, // works with same key
    coston2: process.env.FLARE_API_KEY!,
  },
  customChains: [
    {
      network: 'baseGoerli',
      chainId: 84531,
      urls: {
        apiURL: 'https://goerli.basescan.org/api',
        browserURL: 'https://goerli.basescan.org/',
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
      network: 'kromaSepolia',
      chainId: 2358,
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
      network: 'base',
      chainId: 8453,
      urls: {
        apiURL: 'https://api.basescan.org/api',
        browserURL: 'https://basescan.org/',
      },
    },
    {
      network: 'linea',
      chainId: 59144,
      urls: {
        apiURL: 'https://api.lineascan.build/api',
        browserURL: 'https://lineascan.build/',
      },
    },
    {
      network: 'lineaTestnet',
      chainId: 59140,
      urls: {
        apiURL: 'https://api-testnet.lineascan.build/api',
        browserURL: 'https://goerli.lineascan.build/',
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
    {
      network: 'scrollSepolia',
      chainId: 534351,
      urls: {
        apiURL: 'https://sepolia-blockscout.scroll.io/api',
        browserURL: 'https://sepolia-blockscout.scroll.io/',
      },
    },
    {
      network: 'mantleTestnet',
      chainId: 5001,
      urls: {
        apiURL: 'https://explorer.testnet.mantle.xyz/api',
        browserURL: 'https://explorer.testnet.mantle.xyz/',
      },
    },
    {
      network: 'coston2',
      chainId: 114,
      urls: {
        apiURL: 'https://coston2-explorer.flare.network/api',
        browserURL: 'https://coston2-explorer.flare.network/',
      },
    },
    {
      network: 'flare',
      chainId: 14,
      urls: {
        apiURL: 'https://flare-explorer.flare.network/api',
        browserURL: 'https://flare-explorer.flare.network/',
      },
    },
    {
      network: 'scroll',
      chainId: 534352,
      urls: {
        apiURL: 'https://api.scrollscan.com/api',
        browserURL: 'https://scrollscan.com/',
      },
    },
  ],
};

export default etherscan;
