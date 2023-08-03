import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployEtherspotWalletFactoryAndImplementation: DeployFunction =
  async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy, execute, read } = deployments;
    const { from } = await getNamedAccounts();
    const ENTRYPOINT = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789';

    console.log('starting deployment of wallet factory and implementation...');
    console.log('starting wallet factory...');

    const ewf = await deploy('EtherspotWalletFactory', {
      from,
      args: [from],
      gasLimit: 6e6,
      // gasLimit: 1000000000, // arbitrum
      log: true,
      deterministicDeployment: true,
    });
    console.log(
      `EtherspotWalletFactory deployed at: ${ewf.address} using ${ewf.receipt?.gasUsed}`
    );

    console.log('starting implementation...');

    const impl = await deploy('EtherspotWallet', {
      from,
      args: [ENTRYPOINT, ewf.address],
      log: true,
    });
    console.log('Implementation deployed at:', impl.address);

    console.log('setting implementation in wallet factory...');

    await execute(
      'EtherspotWalletFactory',
      { from, log: true },
      'setImplementation',
      impl.address
    );

    console.log(
      `check implementation matches: ${await read(
        'EtherspotWalletFactory',
        'accountImplementation'
      )} == ${impl.address}`
    );
    console.log(`Done!`);
  };

deployEtherspotWalletFactoryAndImplementation.tags = [
  'aa-4337',
  'etherspot-wallet-factory-and-implementation',
  'required',
];

export default deployEtherspotWalletFactoryAndImplementation;
