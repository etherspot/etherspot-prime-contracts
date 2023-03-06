/* eslint-disable @typescript-eslint/camelcase */
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import {
  EtherspotWallet,
  EtherspotWalletFactory__factory,
  PersonalAccountRegistry,
  PersonalAccountRegistry__factory,
  TestUtil,
  TestUtil__factory,
} from '../../typings';
import {
  createAddress,
  createAccountOwner,
  createEtherspotWallet,
  getBalance,
  isDeployed,
  ONE_ETH,
  HashZero,
  AddressZero,
} from '../aa-4337/helpers/testutils';
import {
  fillUserOpDefaults,
  getUserOpHash,
  packUserOp,
  signUserOp,
} from '../aa-4337/user_ops/UserOp';
import { parseEther } from 'ethers/lib/utils';
import { UserOperation } from '../aa-4337/user_ops/UserOperation';

describe('EtherspotWallet', function () {
  const entryPoint = '0x'.padEnd(42, '2');
  let registry: PersonalAccountRegistry;
  let accounts: string[];
  let testUtil: TestUtil;
  let accountOwner: Wallet;
  const ethersSigner = ethers.provider.getSigner();

  before(async function () {
    accounts = await ethers.provider.listAccounts();
    // ignore in geth.. this is just a sanity test. should be refactored to use a single-account mode..
    if (accounts.length < 2) this.skip();
    registry = await new PersonalAccountRegistry__factory(
      ethersSigner
    ).deploy();
    testUtil = await new TestUtil__factory(ethersSigner).deploy();
    accountOwner = createAccountOwner();
  });

  it('owner should be able to call transfer', async () => {
    const { proxy: account } = await createEtherspotWallet(
      ethers.provider.getSigner(),
      accounts[0],
      entryPoint,
      registry.address
    );
    await ethersSigner.sendTransaction({
      from: accounts[0],
      to: account.address,
      value: parseEther('2'),
    });
    await account.execute(accounts[2], ONE_ETH, '0x');
  });
  it('other account should not be able to call transfer', async () => {
    const { proxy: account } = await createEtherspotWallet(
      ethers.provider.getSigner(),
      accounts[0],
      entryPoint,
      registry.address
    );
    await expect(
      account
        .connect(ethers.provider.getSigner(1))
        .execute(accounts[2], ONE_ETH, '0x')
    ).to.be.revertedWith('EtherspotWallet:: not Owner or EntryPoint');
  });

  it('should pack in js the same as solidity', async () => {
    const op = await fillUserOpDefaults({ sender: accounts[0] });
    const packed = packUserOp(op);
    expect(await testUtil.packUserOp(op)).to.equal(packed);
  });

  describe('#validateUserOp', () => {
    let account: EtherspotWallet;
    let userOp: UserOperation;
    let userOpHash: string;
    let preBalance: number;
    let expectedPay: number;

    const actualGasPrice = 1e9;

    before(async () => {
      // that's the account of ethersSigner
      const entryPoint = accounts[2];
      ({ proxy: account } = await createEtherspotWallet(
        await ethers.getSigner(entryPoint),
        accountOwner.address,
        entryPoint,
        registry.address
      ));
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('0.2'),
      });
      const callGasLimit = 200000;
      const verificationGasLimit = 100000;
      const maxFeePerGas = 3e9;
      const chainId = await ethers.provider
        .getNetwork()
        .then((net) => net.chainId);

      userOp = signUserOp(
        fillUserOpDefaults({
          sender: account.address,
          callGasLimit,
          verificationGasLimit,
          maxFeePerGas,
        }),
        accountOwner,
        entryPoint,
        chainId
      );

      userOpHash = await getUserOpHash(userOp, entryPoint, chainId);

      expectedPay = actualGasPrice * (callGasLimit + verificationGasLimit);

      preBalance = await getBalance(account.address);
      const ret = await account.validateUserOp(
        userOp,
        userOpHash,
        expectedPay,
        { gasPrice: actualGasPrice }
      );
      await ret.wait();
    });

    it('should pay', async () => {
      const postBalance = await getBalance(account.address);
      expect(preBalance - postBalance).to.eql(expectedPay);
    });

    it('should increment nonce', async () => {
      expect(await account.nonce()).to.equal(1);
    });
    it('should reject same TX on nonce error', async () => {
      await expect(
        account.validateUserOp(userOp, userOpHash, 0)
      ).to.revertedWith('EtherspotWallet:: invalid nonce');
    });
    it('should return NO_SIG_VALIDATION on wrong signature', async () => {
      const userOpHash = HashZero;
      const deadline = await account.callStatic.validateUserOp(
        { ...userOp, nonce: 1 },
        userOpHash,
        0
      );
      expect(deadline).to.eq(1);
    });
  });

  describe('#updateEntryPoint', async () => {
    it('should update EntryPoint contract address', async () => {
      const entryPoint1 = '0x'.padEnd(42, '3');
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint,
        registry.address
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      const oldEntryPoint = await account.entryPoint();
      await account.updateEntryPoint(entryPoint1);
      const newEntryPoint = await account.entryPoint();
      expect(oldEntryPoint).to.not.eq(newEntryPoint);
      expect(newEntryPoint).to.eq(entryPoint1);
    });
    it('should trigger error if zero address passed in', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint,
        registry.address
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await expect(account.updateEntryPoint(AddressZero)).to.be.revertedWith(
        'EtherspotWallet:: EntryPoint address cannot be zero'
      );
    });
  });

  describe('#updateRegistry', async () => {
    it('should update Registry contract address', async () => {
      const registry1 = '0x'.padEnd(42, '3');
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint,
        registry.address
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      const oldRegistry = await account.registry();
      await account.updateRegistry(registry1);
      const newRegistry = await account.registry();
      expect(oldRegistry).to.not.eq(newRegistry);
      expect(newRegistry).to.eq(registry1);
    });
    it('should trigger error if zero address passed in', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint,
        registry.address
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await expect(account.updateRegistry(AddressZero)).to.be.revertedWith(
        'EtherspotWallet:: Registry address cannot be zero'
      );
    });
  });

  context('EtherspotWalletFactory', () => {
    it('sanity: check deployer', async () => {
      const ownerAddr = createAddress();
      const deployer = await new EtherspotWalletFactory__factory(
        ethersSigner
      ).deploy();
      const target = await deployer.callStatic.createAccount(
        entryPoint,
        registry.address,
        ownerAddr,
        1234
      );
      expect(await isDeployed(target)).to.eq(false);
      await deployer.createAccount(
        entryPoint,
        registry.address,
        ownerAddr,
        1234
      );
      expect(await isDeployed(target)).to.eq(true);
    });
  });
});
