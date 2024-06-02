import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const verifyWalletFactoryAndImplementation: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { getNamedAccounts } = hre;
  const { from } = await getNamedAccounts();

  const ENTRYPOINT_ADDRESS = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789';
  const WALLET_FACTORY_ADDRESS = '0x7f6d8F107fE8551160BD5351d5F1514A6aD5d40E';
  const WALLET_IMPLEMENTATION_ADDRESS =
    '0xfB32cef50CfB0A0F9f6d37A05828b2F56EfdfE20';

  console.log('starting verification...');
  console.log('verifying wallet factory...');
  await hre.run('verify:verify', {
    address: WALLET_FACTORY_ADDRESS,
    contract:
      'src/etherspot-wallet-v1/wallet/EtherspotWalletFactory.sol:EtherspotWalletFactory',
    constructorArguments: [from],
  });

  console.log('verifying wallet implementation...');
  await hre.run('verify:verify', {
    address: WALLET_IMPLEMENTATION_ADDRESS,
    contract:
      'src/etherspot-wallet-v1/wallet/EtherspotWallet.sol:EtherspotWallet',
    constructorArguments: [ENTRYPOINT_ADDRESS, WALLET_FACTORY_ADDRESS],
  });

  console.log('completed verification!');
};

verifyWalletFactoryAndImplementation.tags = [
  'aa-4337',
  'verify-wallet-factory-contracts',
];

export default verifyWalletFactoryAndImplementation;
