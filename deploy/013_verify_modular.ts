import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const verifyModular: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { getNamedAccounts } = hre;
  const { from } = await getNamedAccounts();

  const FACTORY_ADDRESS = '0x5952653F151e844346825050d7157A9a6b46A23A';
  const IMPLEMENTATION_ADDRESS = '0x9A54329dCEc6b961F788bE5017110ac30c76b107';
  const BOOTSTRAP_ADDRESS = '0x805650ce74561C85baA44a8Bd13E19633Fd0F79d';
  const ECDSA_VALIDATOR_ADDRESS = '0x68BA597bf6B9097b1D89b8E0D34646D30997f773';
  const SESSION_KEY_VALIDATOR_ADDRESS =
    '0x4ebd86AAF89151b5303DB072e0205C668e31E5E7';

  console.log('starting verification...');

  await hre.run('verify:verify', {
    address: FACTORY_ADDRESS,
    contract:
      'src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol:ModularEtherspotWalletFactory',
    constructorArguments: [IMPLEMENTATION_ADDRESS, from],
  });

  await hre.run('verify:verify', {
    address: IMPLEMENTATION_ADDRESS,
    contract:
      'src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol:ModularEtherspotWallet',
    constructorArguments: [],
  });

  await hre.run('verify:verify', {
    address: BOOTSTRAP_ADDRESS,
    contract:
      'src/modular-etherspot-wallet/erc7579-ref-impl/utils/Bootstrap.sol:Bootstrap',
    constructorArguments: [],
  });

  await hre.run('verify:verify', {
    address: ECDSA_VALIDATOR_ADDRESS,
    contract:
      'src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator.sol:MultipleOwnerECDSAValidator',
    constructorArguments: [],
  });

  await hre.run('verify:verify', {
    address: SESSION_KEY_VALIDATOR_ADDRESS,
    contract:
      'src/modular-etherspot-wallet/modules/validators/ERC20SessionKeyValidator.sol:ERC20SessionKeyValidator',
    constructorArguments: [],
  });
};

verifyModular.tags = ['verify-modular'];

export default verifyModular;
