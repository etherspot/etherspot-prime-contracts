import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployEtherspotWalletFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const EXPECTED_CREATE2_ADDRESS = '0x27f11918740060bd9Be146086F6836e18eedBB8C';
  const { deployments, getNamedAccounts } = hre;
  const { deploy, deterministic } = deployments;
  const { from } = await getNamedAccounts();

  console.log('starting deployment of wallet factory...');

  const determined = await deterministic('EtherspotWalletFactory', {
    from,
    args: [],
    log: true,
  });

  console.log(`Expected address: ${EXPECTED_CREATE2_ADDRESS}`);
  console.log(`Pre-determined address: ${determined.address}`);

  if (determined.address !== EXPECTED_CREATE2_ADDRESS) {
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

    await hre.run('verify:verify', {
      address: ret.address,
      contract: 'src/wallet/EtherspotWalletFactory.sol:EtherspotWalletFactory',
      constructorArguments: [],
    });
  }
};

deployEtherspotWalletFactory.tags = [
  'aa-4337',
  'etherspot-wallet-factory',
  'required',
];

export default deployEtherspotWalletFactory;
