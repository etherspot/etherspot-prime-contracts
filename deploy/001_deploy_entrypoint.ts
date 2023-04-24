import { DeployFunction } from 'hardhat-deploy/types';

const deployEntryPoint: DeployFunction = async (hre) => {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { from } = await getNamedAccounts();

  const ret = await deploy('EntryPoint', {
    from,
    args: [],
    log: true,
    deterministicDeployment: true,
  });
  console.log('EntryPoint deployed at:', ret.address);
};

deployEntryPoint.tags = ['aa-4337', 'entry-point'];

module.exports = deployEntryPoint;
