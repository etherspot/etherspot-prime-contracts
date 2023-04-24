import { DeployFunction } from 'hardhat-deploy/types';

const deployEtherspotWalletFactory: DeployFunction = async (hre) => {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { from } = await getNamedAccounts();

  const ret = await deploy('EtherspotWalletFactory', {
    from,
    args: [],
    gasLimit: 6e6,
    deterministicDeployment: true,
  });
  console.log('EtherspotWalletFactory deployed at:', ret.address);
};

deployEtherspotWalletFactory.tags = ['aa-4337', 'etherspot-wallet-factory'];

module.exports = deployEtherspotWalletFactory;
