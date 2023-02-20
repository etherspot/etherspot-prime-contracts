import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
    ethers,
  } = hre;
  const { from } = await getNamedAccounts();

  // Get EntryPoint contract
  const entryPoint = await ethers.getContract('EntryPoint');
  console.log(`EntryPoint contract address: ${entryPoint.address}`);

  await deploy('EtherspotPaymaster', {
    from,
    args: [entryPoint.address],
    log: true,
    deterministicDeployment: true,
  });

  // Get EtherspotPaymaster contract address for Etherscan verification
  const etherspotPaymaster = await ethers.getContract('EtherspotPaymaster');

  console.log(`EtherspotPaymaster deployed to: ${etherspotPaymaster.address}`);
};

func.tags = ['aa-4337', 'etherspot-paymaster'];

export default func;
