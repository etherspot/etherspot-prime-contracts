import { ethers } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployERC20Paymaster: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { from } = await getNamedAccounts();

  console.log('starting deployment of paymaster...');

  const token = '0x453478E2E0c846c069e544405d5877086960BEf2';
  // const token = '0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904'; //amoy
  // const tokenOracle ='0xBAb4d175f1c8255C6c44B2cE6664eEC5bc9d7A3A';
  // const tokenOracle = '0xD241C19C5AB952123e64900Adc92C74a2a17ee01'; // amoy
  // const tokenOracle = '0x089584cCB94CabD9C88D826dB4c441C330EBCA96'; // amoy new
  const tokenOracle = '0x1310F6cB60D99fb2bB6AdEB4F5449156D2dcb8eD'; // xdc new
  // const nativeAssetOracle = '0x4347b916829EFE9E05485eb226A5949028fb8291';
  // const nativeAssetOracle = '0x2223d8Eb10E947d9FcDF3A796bd550244F3AbD32'; //amoy
  // const nativeAssetOracle = '0x89e417A318Af12154E210514651Fb79EE7de542d'; //amoy new
  const nativeAssetOracle = '0x5881E0238Ace27e32110Bd6EabC53d5f7Ee78829'; //xdc new
  const stalenessThreshold = 3000 * 24 * 60 * 60; // As its testnet
  const owner = '0x09FD4F6088f2025427AB1e89257A44747081Ed59';
  const priceMarkupLimit = 10000000;
  const priceMarkup = 1000000;
  const refundPostOpCost = 30000;
  const refundPostOpCostWithGuarantor = 50000;
  const entrypoint = '0x0000000071727De22E5E9d8BAf0edAc6f37da032';
  const ret = await deploy('ERC20Paymaster', {
    from,
    args: [token, entrypoint, tokenOracle, nativeAssetOracle, stalenessThreshold, from, priceMarkupLimit, priceMarkup, refundPostOpCost, refundPostOpCostWithGuarantor],
    gasLimit: 8e6,
    // gasLimit: 1000000000, // arbitrum
    // gasLimit: 10000000, // baseGoerli
    // gasLimit: 20000000, // kromaSepolia
    gasPrice: '40000000000',
    // gasPrice: ''
    log: true,
  });
  console.log('ERC20 Paymaster deployed at:', ret.address);

  console.log('staking paymaster with entry point...');

  await execute(
    'ERC20Paymaster',
    {
      from,
      value: await ethers.utils.parseEther('0.1'),
      log: true,
      gasLimit: 6e6,
    },
    'addStake',
    1
  );

  await execute(
    'ERC20Paymaster',
    {
      from,
      value: await ethers.utils.parseEther('1'),
      log: true,
      gasLimit: 6e6,
    },
    'deposit',
  );

  await hre.run('verify:verify', {
    address: ret.address,
    contract:
      'src/modular-etherspot-wallet/ERC20PaymasterEP07/ERC20PaymasterV07.sol:ERC20Paymaster',
    constructorArguments: [token, entrypoint, tokenOracle, nativeAssetOracle, stalenessThreshold, from, priceMarkupLimit, priceMarkup, refundPostOpCost, refundPostOpCostWithGuarantor],
  });
  console.log('Done!');
};

deployERC20Paymaster.tags = ['deploy-erc20-paymaster'];

module.exports = deployERC20Paymaster;
