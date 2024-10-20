// scripts/deploy.js
import { ethers, run, upgrades } from 'hardhat';
const hre = require("hardhat");
import * as dotenv from 'dotenv';
// import { admin } from '@openzeppelin/upgrades-core';
dotenv.config()

// npx hardhat run script/deploy-erc20-sessionkey-validator.ts --network amoy
async function main() {
    const ERC20SessionKeyValidator = await ethers.getContractFactory("ERC20SessionKeyValidator");
    console.log("Deploying ERC20SessionKeyValidator...");
    const ERC20SessionKeyValidatorDeployedContract = await ERC20SessionKeyValidator.deploy();
    console.log(`ERC20SessionKeyValidator deployed to: ${ERC20SessionKeyValidatorDeployedContract.address}`);
    const erc20SessionKeyValidatorContract = await ERC20SessionKeyValidator.deployed();
    console.log(`✅ Deployed ERC20SessionKeyValidator to: ${erc20SessionKeyValidatorContract.address}`);
    console.log(`About to wait for 5 seconds to verify the contract...`);
    await sleep(5000);
    console.log("Verifying ERC20SessionKeyValidator contract...");
    await hre.run("verify:verify", {
        address: erc20SessionKeyValidatorContract.address,
    });
}

// Define a sleep function
function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

main()
  .catch(console.error)
  .finally(() => process.exit());