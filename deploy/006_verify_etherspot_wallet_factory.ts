import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const verifyWalletFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { from } = await getNamedAccounts();

  const WALLET_FACTORY_ADDRESS = '0x7f6d8F107fE8551160BD5351d5F1514A6aD5d40E';

  console.log('starting verification...');

  await hre.run('verify:verify', {
    address: WALLET_FACTORY_ADDRESS,
    contract: 'src/wallet/EtherspotWalletFactory.sol:EtherspotWalletFactory',
    constructorArguments: [from],
  });
};

verifyWalletFactory.tags = ['aa-4337', 'verify-wallet-factory-contract'];

export default verifyWalletFactory;
