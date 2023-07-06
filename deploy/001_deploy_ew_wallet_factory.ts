import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployEtherspotWalletFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { from } = await getNamedAccounts();

  console.log('starting deployment of wallet factory...');

  const ret = await deploy('EtherspotWalletFactory', {
    from,
    args: [],
    gasLimit: 6e6,
    // gasLimit: 1000000000, // arbitrum
    log: true,
    deterministicDeployment: true,
  });
  console.log('EtherspotWalletFactory deployed at:', ret.address);

  await hre.run('verify:verify', {
    address: ret.address,
    contract: 'src/wallet/EtherspotWalletFactory.sol:EtherspotWalletFactory',
    constructorArguments: [],
  });
};

deployEtherspotWalletFactory.tags = [
  'aa-4337',
  'etherspot-wallet-factory',
  'required',
];

export default deployEtherspotWalletFactory;
