/* eslint-disable @typescript-eslint/camelcase */
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import {
  EtherspotWalletFactory,
  EtherspotWalletFactory__factory,
} from '../../typings';
import {
  createAccountOwner,
} from '../../account-abstraction/test/testutils';

describe("Factory", () => {
  const ethersSigner = ethers.provider.getSigner();
  const entryPoint = '0x'.padEnd(42, '2');
  let accounts: string[];
  let accountOwner: Wallet;
  let accountFactory: EtherspotWalletFactory;

  before(async function () {
    accounts = await ethers.provider.listAccounts();
    // ignore in geth.. this is just a sanity test. should be refactored to use a single-account mode..
    if (accounts.length < 2) this.skip();
    accountOwner = createAccountOwner();
    accountFactory = await (new EtherspotWalletFactory__factory(ethersSigner)).deploy();
  });

  it("should get counter factual address", async () => {
    const counterFactualAddress = await accountFactory.getAddress(entryPoint, accounts[0], 0);
    const callStaticAddress = await accountFactory.callStatic.createAccount(entryPoint, accounts[0], 0);
    expect(counterFactualAddress).to.not.eq(ethers.constants.AddressZero);
    expect(callStaticAddress).to.eq(counterFactualAddress);
  });

  it("counter-factual address should match deployed address", async () => {
    const counterFactualAddress = await accountFactory.getAddress(entryPoint, accounts[0], 0);
    const accountDeployTx = await (await accountFactory.createAccount(entryPoint, accounts[0], 0)).wait();    
    const deployEvent = accountDeployTx.events?.find((event: any) => event.event === 'AccountCreation');

    expect(deployEvent).to.not.eq(undefined);
    if (deployEvent) {
      expect(counterFactualAddress).to.eq(deployEvent.args!.at(0));
    }
  });
})