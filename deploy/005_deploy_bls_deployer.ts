import { DeployFunction } from 'hardhat-deploy/types';

const deployBLSAccountFactory: DeployFunction = async (hre) => {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { from } = await getNamedAccounts();

  await deploy('contract BLSAccountFactory', {
    from,
    log: true,
    deterministicDeployment: true,
  });
};

deployBLSAccountFactory.tags = ['aa-4337', 'bls-account-factory'];

module.exports = deployBLSAccountFactory;
