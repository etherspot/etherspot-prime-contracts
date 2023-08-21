import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployEtherspotPaymaster: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { from } = await getNamedAccounts();

  console.log('starting deployment of paymaster...');

  const entrypoint = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789';
  const ret = await deploy('EtherspotPaymaster', {
    from,
    args: [entrypoint],
    gasLimit: 6e6,
    // gasLimit: 1000000000, // arbitrum
    // gasLimit: 9000000, // baseGoerli
    log: true,
  });
  console.log('EtherspotPaymaster deployed at:', ret.address);
};

deployEtherspotPaymaster.tags = ['aa-4337', 'etherspot-paymaster', 'required'];

module.exports = deployEtherspotPaymaster;
