import { ethers } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployVerifyingPaymaster: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { from } = await getNamedAccounts();

  console.log('starting deployment of verifying paymaster...');

  const entrypoint = '0x0000000071727De22E5E9d8BAf0edAc6f37da032';
  const verifyingSigner = '0xaeAF09795d8C0e6fA4bB5f89dc9c15EC02021567';
  const ret = await deploy('VerifyingPaymaster', {
    from,
    args: [entrypoint, verifyingSigner],
    gasLimit: 6e6,
    // gasLimit: 1000000000, // arbitrum
    // gasLimit: 10000000, // baseGoerli
    // gasLimit: 20000000, // kromaSepolia
    log: true,
  });
  console.log('VerifyingPaymaster deployed at:', ret.address);

  console.log('staking paymaster with entry point...');

  await execute(
    'VerifyingPaymaster',
    {
      from,
      value: await ethers.utils.parseEther('0.01'),
      log: true,
      gasLimit: 6e6,
    },
    'addStake',
    1
  );

  await execute(
    'VerifyingPaymaster',
    {
      from,
      value: await ethers.utils.parseEther('100'),
      log: true,
      gasLimit: 6e6,
    },
    'deposit'
  );
  console.log('Done!');
};

deployVerifyingPaymaster.tags = [
  'aa-4337',
  'deploy-verifying-paymaster',
  'required',
];

module.exports = deployVerifyingPaymaster;
