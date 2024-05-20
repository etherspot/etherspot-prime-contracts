import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const verifyVerifyingPaymaster: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const PAYMASTER_ADDRESS = '0x810FA4C915015b703db0878CF2B9344bEB254a40'; // Add deployed paymaster address to verify
  const ENTRY_POINT_ADDRESS = '0x0000000071727De22E5E9d8BAf0edAc6f37da032';
  const VERIFYING_SIGNER_ADDRESS = '0x09FD4F6088f2025427AB1e89257A44747081Ed59';

  console.log('starting verification...');

  await hre.run('verify:verify', {
    address: PAYMASTER_ADDRESS,
    contract:
      'src/etherspot-wallet-v1/paymaster/VerifyingPaymaster.sol:VerifyingPaymaster',
    constructorArguments: [ENTRY_POINT_ADDRESS, VERIFYING_SIGNER_ADDRESS],
  });
};

verifyVerifyingPaymaster.tags = ['aa-4337', 'verify-verifying-paymaster'];

export default verifyVerifyingPaymaster;
