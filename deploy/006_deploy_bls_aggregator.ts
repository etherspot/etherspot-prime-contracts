import { DeployFunction } from 'hardhat-deploy/types';

const deployBLSSignatureAggregator: DeployFunction = async (hre) => {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { from } = await getNamedAccounts();

  const BLSOpenContract = await hre.deployments.get('BLSOpen');

  await deploy('BLSSignatureAggregator', {
    from,
    log: true,
    deterministicDeployment: true,
    libraries: {
      BLSOpen: BLSOpenContract.address,
    },
  });
};

deployBLSSignatureAggregator.tags = ['aa-4337', 'bls-signature-aggregator'];

module.exports = deployBLSSignatureAggregator;
