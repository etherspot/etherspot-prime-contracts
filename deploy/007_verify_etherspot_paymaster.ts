import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const verifyPaymaster: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const PAYMASTER_ADDRESS = '0xF3E89e89A539505FFF1cAbac2bF9a55401ECa3d5';
  const ENTRY_POINT_ADDRESS = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789';

  console.log('starting verification...');

  await hre.run('verify:verify', {
    address: PAYMASTER_ADDRESS,
    contract: 'src/paymaster/EtherspotPaymaster.sol:EtherspotPaymaster',
    constructorArguments: [ENTRY_POINT_ADDRESS],
  });
};

verifyPaymaster.tags = ['aa-4337', 'verify-paymaster-contract'];

export default verifyPaymaster;