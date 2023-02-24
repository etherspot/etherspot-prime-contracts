/* eslint-disable @typescript-eslint/camelcase */
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import {
  EtherspotAccount,
  EntryPoint,
  EtherspotPaymaster,
  EtherspotPaymaster__factory,
  EtherspotAccountFactory__factory,
} from '../typings';
import {
  AddressZero,
  createAccount,
  createAccountOwner,
  createAddress,
  deployEntryPoint,
  simulationResultCatch,
} from './helpers/testUtils';
import { fillAndSign } from './UserOp';
import { arrayify, hexConcat, parseEther } from 'ethers/lib/utils';
import { UserOperation } from './UserOperation';

describe('EntryPoint with EtherspotPaymaster', function () {
  let entryPoint: EntryPoint;
  let accountOwner: Wallet;
  let wlaccOwner: Wallet;
  const ethersSigner = ethers.provider.getSigner();
  let account: EtherspotAccount;
  let wlaccount: EtherspotAccount;
  let offchainSigner: Wallet;
  let offchainSigner1: Wallet;
  let funder: any;
  let acc1: any;
  let acc2: any;
  let paymaster: EtherspotPaymaster;
  let intpaymaster: any;

  const abicode = new ethers.utils.AbiCoder();
  const SUCCESS_OP = 0;
  const FAIL_OP = 2;
  const HASH =
    '0xead571b8d3ed9e40e7cb1d44db5a7ecc1e4297e2fc6a69235bf61f1c6a43c605';
  const GAS_COST = 158574;

  beforeEach(async () => {
    [funder, acc1, acc2] = await ethers.getSigners();

    this.timeout(20000);
    entryPoint = await deployEntryPoint();

    offchainSigner = createAccountOwner();
    offchainSigner1 = createAccountOwner();
    accountOwner = createAccountOwner();
    wlaccOwner = createAccountOwner();

    paymaster = await new EtherspotPaymaster__factory(ethersSigner).deploy(
      entryPoint.address
    );

    await paymaster.addStake(1, { value: parseEther('2') });
    await entryPoint.depositTo(paymaster.address, { value: parseEther('1') });
    ({ proxy: account } = await createAccount(
      ethersSigner,
      accountOwner.address,
      entryPoint.address
    ));
    ({ proxy: wlaccount } = await createAccount(
      ethersSigner,
      wlaccOwner.address,
      entryPoint.address
    ));

    await funder.sendTransaction({
      to: offchainSigner.address,
      value: ethers.utils.parseEther('10.0'),
    });
    await funder.sendTransaction({
      to: offchainSigner1.address,
      value: ethers.utils.parseEther('10.0'),
    });
  });

  describe('whitelist integration check', () => {
    it('should be able to interact with whitelist', async () => {
      await paymaster.connect(acc1).add(acc2.address);
      expect(await paymaster.check(acc1.address, acc2.address)).to.be.true;
      await paymaster.connect(acc1).remove(acc2.address);
      expect(await paymaster.check(acc1.address, acc2.address)).to.be.false;
    });
  });

  describe('#validatePaymasterUserOp', () => {
    it('should reject on no signature', async () => {
      const userOp = await fillAndSign(
        {
          sender: account.address,
          paymasterAndData: hexConcat([paymaster.address, '0x1234']),
        },
        accountOwner,
        entryPoint
      );
      await expect(
        entryPoint.callStatic.simulateValidation(userOp)
      ).to.be.revertedWith('invalid signature length in paymasterAndData');
    });

    it('should reject on invalid signature', async () => {
      const userOp = await fillAndSign(
        {
          sender: account.address,
          paymasterAndData: hexConcat([
            paymaster.address,
            '0x' + '00'.repeat(65),
          ]),
        },
        accountOwner,
        entryPoint
      );
      await expect(
        entryPoint.callStatic.simulateValidation(userOp)
      ).to.be.revertedWith('ECDSA: invalid signature');
    });

    describe('with wrong signature', () => {
      let wrongSigUserOp: UserOperation;
      const beneficiaryAddress = createAddress();
      before(async () => {
        const sig = await offchainSigner.signMessage(arrayify('0xdead'));
        wrongSigUserOp = await fillAndSign(
          {
            sender: account.address,
            paymasterAndData: hexConcat([paymaster.address, sig]),
          },
          accountOwner,
          entryPoint
        );
      });

      it('should return signature error (no revert) on wrong signer signature', async () => {
        const ret = await entryPoint.callStatic
          .simulateValidation(wrongSigUserOp)
          .catch(simulationResultCatch);
        expect(ret.returnInfo.sigFailed).to.be.true;
      });

      it('handleOp revert on signature failure in handleOps', async () => {
        await expect(
          entryPoint.estimateGas.handleOps([wrongSigUserOp], beneficiaryAddress)
        ).to.revertedWith('AA34 signature error');
      });
    });

    it('succeed with valid signature', async () => {
      await paymaster.connect(offchainSigner).add(account.address);
      await paymaster
        .connect(offchainSigner)
        .depositFunds({ value: ethers.utils.parseEther('2.0') });

      const userOp1 = await fillAndSign(
        {
          sender: account.address,
        },
        accountOwner,
        entryPoint
      );

      const hash = await paymaster.getHash(userOp1);
      const sig = await offchainSigner.signMessage(arrayify(hash));

      const userOp = await fillAndSign(
        {
          ...userOp1,
          paymasterAndData: hexConcat([paymaster.address, sig]),
        },
        accountOwner,
        entryPoint
      );

      const ret = await entryPoint.callStatic
        .simulateValidation(userOp)
        .catch(simulationResultCatch);
      expect(ret.returnInfo.sigFailed).to.be.false;
    });

    it('should reject if not a whitelisted signature', async () => {
      const userOp2 = await fillAndSign(
        {
          sender: account.address,
        },
        accountOwner,
        entryPoint
      );

      const hash = await paymaster.getHash(userOp2);
      const sig = await offchainSigner.signMessage(arrayify(hash));

      const userOp = await fillAndSign(
        {
          ...userOp2,
          paymasterAndData: hexConcat([paymaster.address, sig]),
        },
        accountOwner,
        entryPoint
      );

      const ret = await entryPoint.callStatic
        .simulateValidation(userOp)
        .catch(simulationResultCatch);

      expect(ret.returnInfo.sigFailed).to.be.true;
    });

    it('succeeds if whitelisted signature', async () => {
      await paymaster
        .connect(offchainSigner)
        .depositFunds({ value: ethers.utils.parseEther('2.0') });
      await paymaster.connect(offchainSigner).add(wlaccount.address);
      const userOp2 = await fillAndSign(
        {
          sender: wlaccount.address,
        },
        wlaccOwner,
        entryPoint
      );

      const hash = await paymaster.getHash(userOp2);
      const sig = await offchainSigner.signMessage(arrayify(hash));

      const userOp = await fillAndSign(
        {
          ...userOp2,
          paymasterAndData: hexConcat([paymaster.address, sig]),
        },
        wlaccOwner,
        entryPoint
      );

      const ret = await entryPoint.callStatic
        .simulateValidation(userOp)
        .catch(simulationResultCatch);
      expect(ret.returnInfo.sigFailed).to.be.false;
    });

    it('error thrown if sponsor balance too low', async () => {
      await paymaster
        .connect(offchainSigner)
        .depositFunds({ value: ethers.utils.parseEther('2.0') });
      await paymaster.connect(offchainSigner1).add(wlaccount.address);
      const userOp2 = await fillAndSign(
        {
          sender: wlaccount.address,
        },
        wlaccOwner,
        entryPoint
      );

      const hash = await paymaster.getHash(userOp2);
      const sig = await offchainSigner1.signMessage(arrayify(hash));

      const userOp = await fillAndSign(
        {
          ...userOp2,
          paymasterAndData: hexConcat([paymaster.address, sig]),
        },
        wlaccOwner,
        entryPoint
      );

      await expect(
        entryPoint.callStatic.simulateValidation(userOp)
      ).to.be.revertedWith(
        'EtherspotPaymaster:: Sponsor paymaster funds too low'
      );
    });
  });

  describe('#depositFunds', () => {
    it('fails if sponsor does not have enough balance', async () => {
      await expect(
        paymaster
          .connect(offchainSigner)
          .depositFunds({ value: ethers.utils.parseEther('1000000') })
      ).to.be.revertedWith('EtherspotPaymaster:: Not enough balance');
    });

    it('should succeed in depositing funds', async () => {
      const init = await paymaster.checkSponsorFunds(offchainSigner.address);
      expect(init).to.equal(0);
      await expect(() =>
        paymaster
          .connect(offchainSigner)
          .depositFunds({ value: ethers.utils.parseEther('2.0') })
      ).to.changeEtherBalance(offchainSigner, ethers.utils.parseEther('-2.0'));
      const post = await paymaster.checkSponsorFunds(offchainSigner.address);
      expect(post).to.equal(ethers.utils.parseEther('2.0'));
    });
  });

  // TODO: testing for depositing, paying gas for a userOp and reducing deposited balance

  describe('#_postOp', async () => {
    beforeEach(async () => {
      // deploy internal paymaster test contract
      const Intpaymaster = await ethers.getContractFactory(
        '$EtherspotPaymaster'
      );
      intpaymaster = await Intpaymaster.deploy(entryPoint.address);
      // deposit funds and check ok deposit
      await intpaymaster
        .connect(offchainSigner)
        .depositFunds({ value: ethers.utils.parseEther('2.0') });
    });

    it('should debit funds from sponsor on successful UserOp execution', async () => {
      const init = await intpaymaster.checkSponsorFunds(offchainSigner.address);
      expect(init).to.equal(ethers.utils.parseEther('2'));

      const context = abicode.encode(
        ['address', 'address', 'bytes', 'uint256'],
        [offchainSigner.address, account.address, HASH, 0]
      );

      // call _postOp
      await intpaymaster
        .connect(offchainSigner)
        .$_postOp(SUCCESS_OP, context, GAS_COST);
      const post = await intpaymaster.checkSponsorFunds(offchainSigner.address);
      expect(parseInt(post.toString())).to.equal(
        parseInt(init.toString()) - GAS_COST
      );
    });

    it('should emit success event upon deducting sponsor funds', async () => {
      const context = abicode.encode(
        ['address', 'address', 'bytes', 'uint256'],
        [offchainSigner.address, account.address, HASH, 0]
      );
      await expect(
        intpaymaster
          .connect(offchainSigner)
          .$_postOp(SUCCESS_OP, context, GAS_COST)
      )
        .to.emit(intpaymaster, 'SponsorSuccessful')
        .withArgs(offchainSigner.address, account.address, HASH);
    });

    it('should emit event upon op code revert when sponsoring failed tx', async () => {
      const context = abicode.encode(
        ['address', 'address', 'bytes', 'uint256'],
        [offchainSigner.address, account.address, HASH, 0]
      );
      await expect(
        intpaymaster
          .connect(offchainSigner)
          .$_postOp(FAIL_OP, context, GAS_COST)
      )
        .to.emit(intpaymaster, 'SponsorUnsuccessful')
        .withArgs(offchainSigner.address, account.address, HASH);
    });

    it('should not deduct funds from sponsor if user op fails validation', async () => {
      const init = await intpaymaster.checkSponsorFunds(offchainSigner.address);
      expect(init).to.equal(ethers.utils.parseEther('2'));

      const context = abicode.encode(
        ['address', 'address', 'bytes', 'uint256'],
        [offchainSigner.address, account.address, HASH, 0]
      );

      await intpaymaster
        .connect(offchainSigner)
        .$_postOp(FAIL_OP, context, GAS_COST);

      const post = await intpaymaster.checkSponsorFunds(offchainSigner.address);
      expect(post).to.equal(ethers.utils.parseEther('2'));
      expect(init).to.equal(post);
    });
  });
});
