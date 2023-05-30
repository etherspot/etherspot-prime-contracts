/* eslint-disable @typescript-eslint/camelcase */
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import {
  ERC1967Proxy__factory,
  TestUtil,
  TestUtil__factory,
} from '../../account-abstraction/typechain';
import {
  EtherspotWallet,
  EtherspotWallet__factory,
  EtherspotWalletFactory__factory,
} from '../../typings';
import {
  createAddress,
  createAccountOwner,
  getBalance,
  isDeployed,
  ONE_ETH,
  HashZero,
  AddressZero,
  fund,
} from '../../account-abstraction/test/testutils';
import { createEtherspotWallet } from '../TestUtils';
import {
  fillUserOpDefaults,
  getUserOpHash,
  packUserOp,
  signUserOp,
} from '../../account-abstraction/test/UserOp';
import { parseEther } from 'ethers/lib/utils';
import { UserOperation } from '../../account-abstraction/test/UserOperation';

describe('EtherspotWallet', function () {
  const ethersSigner = ethers.provider.getSigner();
  const entryPoint = '0x'.padEnd(42, '2');
  let accounts: string[];
  let testUtil: TestUtil;
  let accountOwner: Wallet;

  before(async function () {
    accounts = await ethers.provider.listAccounts();
    // ignore in geth.. this is just a sanity test. should be refactored to use a single-account mode..
    if (accounts.length < 2) this.skip();
    testUtil = await new TestUtil__factory(ethersSigner).deploy();
    accountOwner = createAccountOwner();
  });

  it('should deploy wallet', async () => {
    const { proxy: account } = await createEtherspotWallet(
      ethers.provider.getSigner(),
      accounts[0],
      entryPoint
    );
    expect(await account.isOwner(accounts[0])).to.eq(true);
  });

  it('owner should be able to call execute', async () => {
    const { proxy: account } = await createEtherspotWallet(
      ethers.provider.getSigner(),
      accounts[0],
      entryPoint
    );
    await ethersSigner.sendTransaction({
      from: accounts[0],
      to: account.address,
      value: parseEther('2'),
    });
    await account.execute(accounts[2], ONE_ETH, '0x');
  });

  it('owner should be able to call executeBatch', async () => {
    const { proxy: account } = await createEtherspotWallet(
      ethers.provider.getSigner(),
      accounts[0],
      entryPoint
    );
    await ethersSigner.sendTransaction({
      from: accounts[0],
      to: account.address,
      value: parseEther('2'),
    });
    await account.executeBatch(
      [accounts[2], accounts[3]],
      [ONE_ETH, ONE_ETH],
      ['0x', '0x']
    );
  });

  it('a different owner should be able to call execute', async () => {
    const { proxy: account } = await createEtherspotWallet(
      ethers.provider.getSigner(),
      accounts[0],
      entryPoint
    );
    await ethersSigner.sendTransaction({
      from: accounts[0],
      to: account.address,
      value: parseEther('2'),
    });

    await account.addOwner(accounts[1]);
    expect(await account.isOwner(accounts[1])).to.eq(true);

    await account
      .connect(ethers.provider.getSigner(1))
      .execute(accounts[2], ONE_ETH, '0x');
  });

  it('guardian should not be able to call execute', async () => {
    const { proxy: account } = await createEtherspotWallet(
      ethers.provider.getSigner(),
      accounts[0],
      entryPoint
    );

    const accountOwner1 = ethers.provider.getSigner(1);
    await account.addGuardian(accountOwner1.getAddress());

    await expect(
      account.connect(accountOwner1).execute(accounts[2], ONE_ETH, '0x')
    ).to.be.revertedWith('ACL:: not owner or entryPoint');
  });

  it('other account should not be able to call execute', async () => {
    const { proxy: account } = await createEtherspotWallet(
      ethers.provider.getSigner(),
      accounts[0],
      entryPoint
    );
    await expect(
      account
        .connect(ethers.provider.getSigner(1))
        .execute(accounts[2], ONE_ETH, '0x')
    ).to.be.revertedWith('ACL:: not owner or entryPoint');
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
    // for testing directly validateUserOp, we initialize the account with EOA as entryPoint.
    let entryPointEoa: string;

    before(async () => {
      entryPointEoa = accounts[2];
      const epAsSigner = await ethers.getSigner(entryPointEoa);

      // cant use "EtherspotWalletFactory", since it attempts to increment nonce first
      const implementation = await new EtherspotWallet__factory(
        ethersSigner
      ).deploy();
      const proxy = await new ERC1967Proxy__factory(ethersSigner).deploy(
        implementation.address,
        '0x'
      );
      account = EtherspotWallet__factory.connect(proxy.address, epAsSigner);
      await account.initialize(entryPointEoa, accountOwner.address);

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
        entryPointEoa,
        chainId
      );

      userOpHash = await getUserOpHash(userOp, entryPointEoa, chainId);

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

  describe('#validateUserOp - multiple account owners', () => {
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
        entryPoint
      ));
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('0.4'),
      });
      const callGasLimit = 200000;
      const verificationGasLimit = 100000;
      const maxFeePerGas = 3e9;
      const chainId = await ethers.provider
        .getNetwork()
        .then((net) => net.chainId);

      const accountOwner1 = createAccountOwner();
      await fund(accountOwner.address);
      await fund(accountOwner1.address);

      await account.connect(accountOwner).addOwner(accountOwner1.address);
      expect(await account.isOwner(accountOwner1.address)).to.eq(true);

      userOp = signUserOp(
        fillUserOpDefaults({
          sender: account.address,
          callGasLimit,
          verificationGasLimit,
          maxFeePerGas,
        }),
        accountOwner1,
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
        entryPoint
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
        entryPoint
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

  describe('#isOwner', () => {
    it('should return true for valid owner', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      expect(await account.isOwner(accounts[0])).to.eq(true);
    });

    it('should return false for invalid owner', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      expect(await account.isOwner(accounts[1])).to.eq(false);
    });
  });

  describe('#addOwner', () => {
    it('should add a new owner (from owner)', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      expect(await account.isOwner(accounts[1])).to.eq(false);
      await account.addOwner(accounts[1]);
      expect(await account.isOwner(accounts[1])).to.eq(true);
    });

    it('should add a new owner (from guardian)', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });

      const accountOwner1 = createAccountOwner();
      await fund(accountOwner1.address);
      await account.addGuardian(accountOwner1.address);
      expect(await account.isGuardian(accountOwner1.address)).to.eq(true);
      expect(await account.isOwner(accounts[2])).to.eq(false);
      await account.connect(accountOwner1).addOwner(accounts[2]);
      expect(await account.isOwner(accounts[2])).to.eq(true);
    });

    it('should emit event on new owner added', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await expect(account.addOwner(accounts[1]))
        .to.emit(account, 'OwnerAdded')
        .withArgs(accounts[1]);
    });

    it('should trigger error if caller is not owner/guardian', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await account.addGuardian(accounts[1]);
      await expect(
        account.connect(ethers.provider.getSigner(2)).addOwner(accounts[3])
      ).to.be.revertedWith('ACL:: only owner or guardian');
    });

    it('should trigger error if already owner', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await expect(account.addOwner(accounts[0])).to.be.revertedWith(
        'ACL:: already owner'
      );
    });
  });

  describe('#removeOwner', () => {
    it('should remove an owner (from owner)', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await account.addOwner(accounts[1]);
      expect(await account.isOwner(accounts[1])).to.eq(true);
      await account.removeOwner(accounts[1]);
      expect(await account.isOwner(accounts[1])).to.eq(false);
    });

    it('should remove an owner (from guardian)', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });

      const accountOwner1 = createAccountOwner();
      await fund(accountOwner1.address);

      await account.addGuardian(accountOwner1.address);
      expect(await account.isGuardian(accountOwner1.address)).to.eq(true);
      await account.addOwner(accounts[2]);
      expect(await account.isOwner(accounts[2])).to.eq(true);
      await account.connect(accountOwner1).removeOwner(accounts[2]);
      expect(await account.isOwner(accounts[2])).to.eq(false);
    });

    it('should emit event on removal of owner', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await account.addOwner(accounts[1]);
      expect(await account.isOwner(accounts[1])).to.eq(true);
      await expect(account.removeOwner(accounts[1]))
        .to.emit(account, 'OwnerRemoved')
        .withArgs(accounts[1]);
    });

    it('should trigger error caller is not owner', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await account.addOwner(accounts[1]);
      await expect(
        account.connect(ethers.provider.getSigner(2)).removeOwner(accounts[1])
      ).to.be.revertedWith('ACL:: only owner or guardian');
    });

    it('should trigger error if removing self', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });

      const accountOwner1 = ethers.provider.getSigner(1);
      const accountOwner1Addr = await accountOwner1.getAddress();
      await fund(accountOwner1Addr);

      await account.addOwner(accountOwner1Addr);
      await expect(
        account.connect(accountOwner1).removeOwner(accountOwner1Addr)
      ).to.be.revertedWith('ACL:: removing self');
    });

    it('should trigger error if removing a non owner', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await expect(account.removeOwner(accounts[1])).to.be.revertedWith(
        'ACL:: non-existant owner'
      );
    });
  });

  describe('#isGuardian', () => {
    it('should return true for valid guardian', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await account.addGuardian(accounts[1]);
      expect(await account.isGuardian(accounts[1])).to.eq(true);
    });

    it('should return false for invalid guardian', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      expect(await account.isGuardian(accounts[1])).to.eq(false);
    });
  });

  describe('#addGuardian', () => {
    it('should add a new guardian', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      expect(await account.isGuardian(accounts[1])).to.eq(false);
      await account.addGuardian(accounts[1]);
      expect(await account.isGuardian(accounts[1])).to.eq(true);
    });

    it('should trigger error on zero address', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await expect(account.addGuardian(AddressZero)).to.be.revertedWith(
        'ACL:: zero address'
      );
    });

    it('should trigger error on adding existing guardian', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await account.addGuardian(accounts[1]);
      await expect(account.addGuardian(accounts[1])).to.be.revertedWith(
        'ACL:: already guardian'
      );
    });

    it('should emit event on adding guardian', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await expect(account.addGuardian(accounts[1]))
        .to.emit(account, 'GuardianAdded')
        .withArgs(accounts[1]);
    });
  });

  describe('#removeGuardian', () => {
    it('should remove guardian', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      expect(await account.isGuardian(accounts[1])).to.eq(false);
      await account.addGuardian(accounts[1]);
      expect(await account.isGuardian(accounts[1])).to.eq(true);
      await account.removeGuardian(accounts[1]);
      expect(await account.isGuardian(accounts[1])).to.eq(false);
    });

    it('should trigger error on removing non-existant guardian', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await expect(account.removeGuardian(accounts[1])).to.be.revertedWith(
        'ACL:: non-existant guardian'
      );
    });

    it('should emit event on removing guardian', async () => {
      const { proxy: account } = await createEtherspotWallet(
        ethers.provider.getSigner(),
        accounts[0],
        entryPoint
      );
      await ethersSigner.sendTransaction({
        from: accounts[0],
        to: account.address,
        value: parseEther('2'),
      });
      await account.addGuardian(accounts[1]);
      await expect(account.removeGuardian(accounts[1]))
        .to.emit(account, 'GuardianRemoved')
        .withArgs(accounts[1]);
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
        ownerAddr,
        1234
      );
      expect(await isDeployed(target)).to.eq(false);
      await deployer.createAccount(entryPoint, ownerAddr, 1234);
      expect(await isDeployed(target)).to.eq(true);
    });
  });
});
