import { ethers } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const stakePaymaster: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { execute } = deployments;
  const { from } = await getNamedAccounts();

  console.log('staking into entry point for paymaster...');

  await execute(
    'EtherspotPaymaster',
    {
      from,
      value: await ethers.utils.parseEther('0.01'),
      log: true,
      gasLimit: 6e6,
      // gasLimit: 6800000, // baseGoerli
    },
    'addStake',
    1
  );

  console.log('Done!');
};

stakePaymaster.tags = ['aa-4337', 'stake-paymaster-contract'];

export default stakePaymaster;
