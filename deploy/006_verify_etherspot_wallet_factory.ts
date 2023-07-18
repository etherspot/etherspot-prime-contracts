import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const verifyWalletFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const WALLET_FACTORY_ADDRESS = '0x27f11918740060bd9Be146086F6836e18eedBB8C';

  console.log('starting verification...');

  await hre.run('verify:verify', {
    address: WALLET_FACTORY_ADDRESS,
    contract: 'src/wallet/EtherspotWalletFactory.sol:EtherspotWalletFactory',
    constructorArguments: [],
  });
};

verifyWalletFactory.tags = ['aa-4337', 'verify-wallet-factory-contract'];

export default verifyWalletFactory;
