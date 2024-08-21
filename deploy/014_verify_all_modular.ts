import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const verifyAllModular: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { getNamedAccounts } = hre;
  const { from } = await getNamedAccounts();

  const WALLET_FACTORY_ADDRESS = '0xB7361924B4F56af570680d56A03895A16bC54Be0';
  const WALLET_IMPLEMENTATION_ADDRESS =
    '0x9A54329dCEc6b961F788bE5017110ac30c76b107';
  const BOOTSTRAP_ADDRESS = '0x805650ce74561C85baA44a8Bd13E19633Fd0F79d';
  const MULTIPLE_OWNER_ECDSA_VALIDATOR_ADDRESS =
    '0x68BA597bf6B9097b1D89b8E0D34646D30997f773';

  console.log('starting verification...');
  console.log('verifying wallet factory...');
  await hre.run('verify:verify', {
    address: WALLET_FACTORY_ADDRESS,
    contract:
      'src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol:ModularEtherspotWallet',
    constructorArguments: [],
  });

  console.log('verifying wallet implementation...');
  await hre.run('verify:verify', {
    address: WALLET_IMPLEMENTATION_ADDRESS,
    contract:
      'src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol:ModularEtherspotWalletFactory',
    constructorArguments: [WALLET_FACTORY_ADDRESS, from],
  });

  console.log('verifying bootstrap...');
  await hre.run('verify:verify', {
    address: BOOTSTRAP_ADDRESS,
    contract:
      'src/modular-etherspot-wallet/erc7579-ref-impl/utils/Bootstrap.sol:Bootstrap',
    constructorArguments: [],
  });

  console.log('verifying multiple owner ecdsa validator...');
  await hre.run('verify:verify', {
    address: MULTIPLE_OWNER_ECDSA_VALIDATOR_ADDRESS,
    contract:
      'src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator.sol:MultipleOwnerECDSAValidator',
    constructorArguments: [],
  });

  console.log('completed verification!');
};

verifyAllModular.tags = ['verify-all-modular'];

export default verifyAllModular;
