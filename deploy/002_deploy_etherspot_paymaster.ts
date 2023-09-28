import { ethers } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployEtherspotPaymaster: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { from } = await getNamedAccounts();

  console.log('starting deployment of paymaster...');

  const entrypoint = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789';
  const ret = await deploy('EtherspotPaymaster', {
    from,
    args: [entrypoint],
    // gasLimit: 6e6,
    // gasLimit: 1000000000, // arbitrum
    // gasLimit: 10000000, // baseGoerli
    gasLimit: 20000000, // kromaSepolia
    log: true,
  });
  console.log('EtherspotPaymaster deployed at:', ret.address);

  console.log('staking paymaster with entry point...');

  await execute(
    'EtherspotPaymaster',
    {
      from,
      value: await ethers.utils.parseEther('0.01'),
      log: true,
      gasLimit: 20000000,
    },
    'addStake',
    1
  );
  console.log('Done!');
};

deployEtherspotPaymaster.tags = ['aa-4337', 'etherspot-paymaster', 'required'];

module.exports = deployEtherspotPaymaster;
