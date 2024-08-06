import { ethers } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployAllModular: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, read } = deployments;
  const { from } = await getNamedAccounts();
  const ENTRYPOINT_07 = '0x0000000071727De22E5E9d8BAf0edAc6f37da032';

  console.log('starting deployments...');

  console.log('deploying ModularEtherspotWallet...');
  const implementation = await deploy('ModularEtherspotWallet', {
    from,
    args: [],
    gasLimit: 6e6,
    log: true,
  });
  console.log(`ModularEtherspotWallet deployed at: ${implementation.address}`);

  // Wait for 5 blocks
  let currentBlock = await hre.ethers.provider.getBlockNumber();
  while (currentBlock + 5 > (await hre.ethers.provider.getBlockNumber())) {}

  console.log('deploying ModularEtherspotWalletFactory...');
  const factory = await deploy('ModularEtherspotWalletFactory', {
    from,
    args: [implementation.address, from],
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
    )} == ${implementation.address}`
  );

  // Wait for 5 blocks
  currentBlock = await hre.ethers.provider.getBlockNumber();
  while (currentBlock + 5 > (await hre.ethers.provider.getBlockNumber())) {}

  console.log('deploying Bootstrap...');
  const bootstrap = await deploy('Bootstrap', {
    from,
    args: [],
    log: true,
  });
  console.log('Bootstrap deployed at:', bootstrap.address);

  // Wait for 5 blocks
  currentBlock = await hre.ethers.provider.getBlockNumber();
  while (currentBlock + 5 > (await hre.ethers.provider.getBlockNumber())) {}

  console.log('deploying MultipleOwnerECDSAValidator...');
  const ecdsaValidator = await deploy('MultipleOwnerECDSAValidator', {
    from,
    args: [],
    log: true,
  });
  console.log(
    'MultipleOwnerECDSAValidator deployed at:',
    ecdsaValidator.address
  );

  // Wait for 5 blocks
  currentBlock = await hre.ethers.provider.getBlockNumber();
  while (currentBlock + 5 > (await hre.ethers.provider.getBlockNumber())) {}

  // console.log('deploying ERC20SessionKeyValidator...');
  // const sessionKeyValidator = await deploy('ERC20SessionKeyValidator', {
  //   from,
  //   args: [],
  //   log: true,
  // });
  // console.log(
  //   'ERC20SessionKeyValidator deployed at:',
  //   sessionKeyValidator.address
  // );

  console.log('Staking ModularEtherspotWalletFactory with EntryPoint...');
  await execute(
    'ModularEtherspotWalletFactory',
    {
      from,
      value: await ethers.utils.parseEther('0.01'),
      log: true,
      gasLimit: 6e6,
    },
    'addStake',
    ENTRYPOINT_07,
    86400
  );

  console.log(`Done!`);
};

deployAllModular.tags = ['deploy-all-modular'];

export default deployAllModular;
