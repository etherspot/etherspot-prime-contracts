import { DeployFunction } from 'hardhat-deploy/types';

const deployEtherspotPaymaster: DeployFunction = async (hre) => {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { from } = await getNamedAccounts();

  const entrypoint = await hre.deployments.get('EntryPoint');
  const ret = await deploy('EtherspotPaymaster', {
    from,
    args: [entrypoint.address],
    gasLimit: 6e6,
    deterministicDeployment: true,
  });
  console.log('EtherspotWalletFactory deployed at:', ret.address);
};

deployEtherspotPaymaster.tags = ['aa-4337', 'etherspot-paymaster'];

module.exports = deployEtherspotPaymaster;
