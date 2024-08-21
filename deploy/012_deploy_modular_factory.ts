import { ethers } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployModular: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, read } = deployments;
  const { from } = await getNamedAccounts();
  const ENTRYPOINT_07 = '0x0000000071727De22E5E9d8BAf0edAc6f37da032';
  const IMPLEMENTATION = '0x202A5598bDba2cE62bFfA13EcccB04969719Fad9';

  console.log('starting deployments...');

  // Wait for 5 blocks
  let currentBlock = await hre.ethers.provider.getBlockNumber();
  while (currentBlock + 5 > (await hre.ethers.provider.getBlockNumber())) {}

  console.log('deploying ModularEtherspotWalletFactory...');
  const factory = await deploy('ModularEtherspotWalletFactory', {
    from,
    args: [IMPLEMENTATION, from],
    log: true,
  });
  console.log('ModularEtherspotWalletFactory deployed at:', factory.address);

  // Wait for 5 blocks
  currentBlock = await hre.ethers.provider.getBlockNumber();
  while (currentBlock + 5 > (await hre.ethers.provider.getBlockNumber())) {}

  // check implementation set correctly
  console.log('Checking implementation in ModularEtherspotWalletFactory...');
  console.log(
    `check implementation matches: ${await read(
      'ModularEtherspotWalletFactory',
      'implementation'
    )} == ${IMPLEMENTATION}`
  );

  // Wait for 5 blocks
  currentBlock = await hre.ethers.provider.getBlockNumber();
  while (currentBlock + 5 > (await hre.ethers.provider.getBlockNumber())) {}

  console.log('Staking ModularEtherspotWalletFactory with EntryPoint...');
  await execute(
    'ModularEtherspotWalletFactory',
    {
      from,
      value: await ethers.utils.parseEther('0.1'),
      log: true,
      gasLimit: 6e6,
    },
    'addStake',
    ENTRYPOINT_07,
    86400
  );

  console.log(`Done!`);
};

deployModular.tags = ['deploy-modular'];

export default deployModular;
