import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const setWalletImplementation: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, deterministic, execute, read } = deployments;
  const { from } = await getNamedAccounts();
  const ENTRYPOINT = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789';
  const EXPECTED_WALLET_FACTORY_ADDRESS =
    '0x7f6d8F107fE8551160BD5351d5F1514A6aD5d40E';
  const EXPECTED_IMPLEMENTATION_ADDRESS =
    '0xfB32cef50CfB0A0F9f6d37A05828b2F56EfdfE20';

  console.log('deploying determinitic wallet implementation...');
  console.log('checking deterministic address validity...');

  const determined = await deterministic('EtherspotWallet', {
    from,
    args: [ENTRYPOINT, EXPECTED_WALLET_FACTORY_ADDRESS],
    log: true,
  });

  if (determined.address !== EXPECTED_IMPLEMENTATION_ADDRESS) {
    console.log(
      'Pre-detemined implementation address is different to what is expected!'
    );
  } else {
    console.log('deterministic check successful!');
    console.log('deploying wallet implementation...');
    const impl = await deploy('EtherspotWallet', {
      from,
      args: [ENTRYPOINT, EXPECTED_WALLET_FACTORY_ADDRESS],
      log: true,
      deterministicDeployment: true,
    });
    console.log('Implementation deployed at:', impl.address);

    console.log('setting implementation in wallet factory...');

    await execute(
      'EtherspotWalletFactory',
      {
        from,
        gasLimit: 6e6,
        log: true,
      },
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
  }
};

setWalletImplementation.tags = ['aa-4337', 'set-wallet-implementation'];

export default setWalletImplementation;
