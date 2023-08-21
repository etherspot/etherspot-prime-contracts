import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployEtherspotWalletFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const EXPECTED_WALLET_FACTORY_ADDRESS =
    '0x27f11918740060bd9Be146086F6836e18eedBB8C';
  const { deployments, getNamedAccounts } = hre;
  const { deploy, deterministic } = deployments;
  const { from } = await getNamedAccounts();

  console.log('starting deployment of wallet factory...');

  const determined = await deterministic('EtherspotWalletFactory', {
    from,
    args: [],
    log: true,
  });

  if (determined.address !== EXPECTED_WALLET_FACTORY_ADDRESS) {
    console.log('Pre-detemined address is different to what is expected!');
  } else {
    const ret = await deploy('EtherspotWalletFactory', {
      from,
      args: [],
      gasLimit: 6e6,
      // gasLimit: 1000000000, // arbitrum
      log: true,
      deterministicDeployment: true,
    });
    console.log('EtherspotWalletFactory deployed at:', ret.address);
  }
};

deployEtherspotWalletFactory.tags = [
  'aa-4337',
  'etherspot-wallet-factory',
  'required',
];

export default deployEtherspotWalletFactory;