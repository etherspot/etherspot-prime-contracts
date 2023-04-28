import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployEtherspotPaymaster: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { from } = await getNamedAccounts();

  const entrypoint = '<entry_point_address>';
  const ret = await deploy('EtherspotPaymaster', {
    from,
    args: [entrypoint],
    gasLimit: 6e6,
    deterministicDeployment: true,
  });
  console.log('EtherspotPaymaster deployed at:', ret.address);
};

deployEtherspotPaymaster.tags = ['aa-4337', 'etherspot-paymaster'];

module.exports = deployEtherspotPaymaster;
