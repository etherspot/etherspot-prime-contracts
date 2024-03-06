import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-foundry';
import '@openzeppelin/hardhat-upgrades';
import 'hardhat-deploy';
import 'hardhat-exposed';
import { compilers, networks, etherscan } from './config';

const config: HardhatUserConfig = {
  namedAccounts: {
    from: 0,
  },
  solidity: compilers,
  networks: networks,
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
  etherscan: etherscan,
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
