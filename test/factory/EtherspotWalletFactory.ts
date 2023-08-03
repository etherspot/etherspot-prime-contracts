/* eslint-disable @typescript-eslint/camelcase */
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import {
  EtherspotWalletFactory,
  EtherspotWalletFactory__factory,
  EtherspotWallet__factory,
} from '../../typings';
import {
  AddressZero,
  createAccountOwner,
  createAddress,
  isDeployed,
} from '../../account-abstraction/test/testutils';

describe('EtherspotWalletFactory', () => {
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
    accountFactory = await new EtherspotWalletFactory__factory(
      ethersSigner
    ).deploy(await ethersSigner.getAddress());
  });

  it('should set implementation address', async () => {
    const implementation = await new EtherspotWallet__factory(
      ethersSigner
    ).deploy(entryPoint, accountFactory.address);
    await accountFactory.setImplementation(implementation.address);
    const impl = await accountFactory.accountImplementation();
    expect(impl).to.not.eq(AddressZero);
  });

  it('should emit event on setting implementation address', async () => {
    const implementation = await new EtherspotWallet__factory(
      ethersSigner
    ).deploy(entryPoint, accountFactory.address);
    await expect(accountFactory.setImplementation(implementation.address))
      .to.emit(accountFactory, 'ImplementationSet')
      .withArgs(implementation.address);
  });

  async function setImpl() {
    const implementation = await new EtherspotWallet__factory(
      ethersSigner
    ).deploy(entryPoint, accountFactory.address);
    await accountFactory.setImplementation(implementation.address);
  }

  it('should deploy a wallet', async () => {
    await setImpl();
    const ownerAddr = createAddress();
    const target = await accountFactory.callStatic.createAccount(
      ownerAddr,
      1234
    );
    expect(await isDeployed(target)).to.eq(false);
    await accountFactory.createAccount(ownerAddr, 1234);
    expect(await isDeployed(target)).to.eq(true);
  });

  it('should get counter factual address', async () => {
    await setImpl();
    const counterFactualAddress = await accountFactory.getAddress(
      accounts[0],
      0
    );
    const callStaticAddress = await accountFactory.callStatic.createAccount(
      accounts[0],
      0
    );
    expect(counterFactualAddress).to.not.eq(AddressZero);
    expect(callStaticAddress).to.eq(counterFactualAddress);
  });

  it('counter-factual address should match deployed address', async () => {
    await setImpl();
    const counterFactualAddress = await accountFactory.getAddress(
      accounts[0],
      0
    );
    const accountDeployTx = await (
      await accountFactory.createAccount(accounts[0], 0)
    ).wait();
    const deployEvent = accountDeployTx.events?.find(
      (event: any) => event.event === 'AccountCreation'
    );

    expect(deployEvent).to.not.eq(undefined);
    if (deployEvent) {
      expect(counterFactualAddress).to.eq(deployEvent.args!.at(0));
    }
  });

  it('should return address if wallet is already deployed', async () => {
    await setImpl();
    const callStaticAddress = await accountFactory.callStatic.createAccount(
      accounts[0],
      0
    );
    const repeatAddress = await accountFactory.callStatic.createAccount(
      accounts[0],
      0
    );
    expect(callStaticAddress).to.eq(repeatAddress);
  });
});
