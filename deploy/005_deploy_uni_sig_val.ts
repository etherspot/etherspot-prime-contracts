import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployUniversalSigValidator: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { from } = await getNamedAccounts();

  console.log(
    'starting deployment of universal signature validator (EIP-6492)...'
  );

  const entrypoint = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789';
  const ret = await deploy('UniversalSigValidator', {
    from,
    args: [],
    gasLimit: 6e6,
    log: true,
  });
  console.log('UniversalSigValidator deployed at:', ret.address);
};

deployUniversalSigValidator.tags = ['aa-4337', 'universal-signature-validator'];

module.exports = deployUniversalSigValidator;
