import { ethers } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const STAKE_AMOUNT = ethers.utils.parseEther('0.1').toString(); // Stake amount for EntryPoint contract
const DEPOSIT_AMOUNT = ethers.utils.parseEther('0.01').toString(); // Deposit amount to subsidise gas sponsors

const deployTestTokenPaymaster: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { from } = await getNamedAccounts();
  
  const EntryPoint_V07 = "0x0000000071727De22E5E9d8BAf0edAc6f37da032";
  const VerifyingAddress = "0x80a1874E1046B1cc5deFdf4D3153838B72fF94Ac";
  const testTokenPaymaster = await deploy('MultiTokenPaymaster', {
    from,
    args: [from, EntryPoint_V07, VerifyingAddress],
    deterministicDeployment: true,
    log: true,
    gasLimit: 6e6,
  });

  console.log(
    `Multi Token Paymaster deployed at address: ${testTokenPaymaster.address}`
  );

  // stake
  // await execute(
  //   'MultiTokenPaymaster',
  //   {
  //     from,
  //     log: true,
  //     gasLimit: 6e6,
  //     value: STAKE_AMOUNT,
  //   },
  //   'addStake',
  //   1
  // );

  // deposit
  // await execute(
  //   'MultiTokenPaymaster',
  //   {
  //     from,
  //     log: true,
  //     gasLimit: 1e6,
  //     // gasPrice: '100252',
  //     value: DEPOSIT_AMOUNT,
  //   },
  //   'deposit',
  // );

  // await execute(
  //   'MultiTokenPaymaster',
  //   {
  //     from,
  //     log: true,
  //     gasLimit: 6e6,
  //     // gasPrice: '100252',
  //     // value: DEPOSIT_AMOUNT,
  //   },
  //   'withdrawStake',
  //   '0x80a1874E1046B1cc5deFdf4D3153838B72fF94Ac'
  // );

  // await execute(
  //   'MultiTokenPaymaster',
  //   {
  //     from,
  //     log: true,
  //     gasLimit: 6e6
  //   },
  //   'setVerifyingSigner',
  //   '0x75A0653458207f0e2183d938a05b239580A0482f'
  // )

  await hre.run('verify:verify', {
    address: testTokenPaymaster.address,
    contract:
      'src/etherspot-wallet-v1/paymaster/MultiTokenPaymaster.sol:MultiTokenPaymaster',
    constructorArguments: [
      from,
      EntryPoint_V07,
      VerifyingAddress
    ],
  });
};

deployTestTokenPaymaster.tags = [
  'deploy-multi-token-Paymaster',
];

export default deployTestTokenPaymaster;
