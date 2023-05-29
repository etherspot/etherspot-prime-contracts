/* eslint-disable @typescript-eslint/camelcase */
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { EntryPoint } from '../../account-abstraction/typechain';
import {
  EtherspotWallet,
  EtherspotPaymaster,
  EtherspotPaymaster__factory,
} from '../../typings';
import {
  createAccountOwner,
  createAddress,
  deployEntryPoint,
  rethrow,
  simulationResultCatch,
} from '../../account-abstraction/test/testutils';
import { createEtherspotWallet } from '../TestUtils';
import { fillAndSign } from '../../account-abstraction/test/UserOp';
import {
  arrayify,
  defaultAbiCoder,
  hexConcat,
  parseEther,
} from 'ethers/lib/utils';
import { UserOperation } from '../../account-abstraction/test/UserOperation';

describe('EntryPoint with EtherspotPaymaster', function () {
  let entryPoint: EntryPoint;
  let accountOwner: Wallet;
  let wlaccOwner: Wallet;
  const ethersSigner = ethers.provider.getSigner();
  let account: EtherspotWallet;
  let wlaccount: EtherspotWallet;
  let offchainSigner: Wallet;
  let offchainSigner1: Wallet;
  let funder: any;
  let acc1: any;
  let acc2: any;
  let paymaster: EtherspotPaymaster;
  let intpaymaster: any;

  const SUCCESS_OP = 0;
  const FAIL_OP = 2;
  const HASH =
    '0xead571b8d3ed9e40e7cb1d44db5a7ecc1e4297e2fc6a69235bf61f1c6a43c605';
  const GAS_COST = 158574;
  const MOCK_VALID_UNTIL = '0x00000000deadbeef';
  const MOCK_VALID_AFTER = '0x0000000000001234';
  const MOCK_SIG = '0x1234';

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

    await paymaster.addStake(1, { value: parseEther('3') });
    await entryPoint.depositTo(paymaster.address, { value: parseEther('2') });
    ({ proxy: account } = await createEtherspotWallet(
      ethersSigner,
      accountOwner.address,
      entryPoint.address
    ));
    ({ proxy: wlaccount } = await createEtherspotWallet(
      ethersSigner,
      wlaccOwner.address,
      entryPoint.address
    ));

    // await fund(offchainSigner.address, '5.0');
    // await fund(offchainSigner1.address, '5.0');

    await funder.sendTransaction({
      to: offchainSigner.address,
      value: ethers.utils.parseEther('20.0'),
    });
    await funder.sendTransaction({
      to: offchainSigner1.address,
      value: ethers.utils.parseEther('20.0'),
    });
  });

  describe('#parsePaymasterAndData', () => {
    it('should parse data properly', async () => {
      const paymasterAndData = hexConcat([
        paymaster.address,
        defaultAbiCoder.encode(
          ['uint48', 'uint48'],
          [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
        ),
        MOCK_SIG,
      ]);
      const res = await paymaster.parsePaymasterAndData(paymasterAndData);
      expect(res.validUntil).to.be.equal(
        ethers.BigNumber.from(MOCK_VALID_UNTIL)
      );
      expect(res.validAfter).to.be.equal(
        ethers.BigNumber.from(MOCK_VALID_AFTER)
      );
      expect(res.signature).equal(MOCK_SIG);
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
          paymasterAndData: hexConcat([
            paymaster.address,
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            '0x1234',
          ]),
          verificationGasLimit: 120000,
        },
        accountOwner,
        entryPoint
      );
      const revert = await entryPoint.callStatic
        .simulateValidation(userOp)
        .catch((e) => {
          return e.errorArgs.reason;
        });
      expect(revert).to.contain(
        'EtherspotPaymaster:: invalid signature length in paymasterAndData'
      );
    });

    it('should reject on invalid signature', async () => {
      const userOp = await fillAndSign(
        {
          sender: account.address,
          paymasterAndData: hexConcat([
            paymaster.address,
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            '0x' + '00'.repeat(65),
          ]),
          verificationGasLimit: 120000,
        },
        accountOwner,
        entryPoint
      );
      const revert = await entryPoint.callStatic
        .simulateValidation(userOp)
        .catch((e) => {
          return e.errorArgs.reason;
        });
      expect(revert).to.contain('ECDSA: invalid signature');
    });

    describe('with wrong signature', () => {
      let wrongSigUserOp: UserOperation;
      const beneficiaryAddress = createAddress();
      before(async () => {
        const sig = await offchainSigner.signMessage(arrayify('0xdead'));
        wrongSigUserOp = await fillAndSign(
          {
            sender: account.address,
            paymasterAndData: hexConcat([
              paymaster.address,
              defaultAbiCoder.encode(
                ['uint48', 'uint48'],
                [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
              ),
              sig,
            ]),
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
        )
          .to.revertedWithCustomError(entryPoint, 'FailedOp')
          .withArgs(0, 'AA34 signature error');
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
          paymasterAndData: hexConcat([
            paymaster.address,
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            '0x' + '00'.repeat(65),
          ]),
          verificationGasLimit: 120000,
        },
        accountOwner,
        entryPoint
      );

      const hash = await paymaster.getHash(
        userOp1,
        MOCK_VALID_UNTIL,
        MOCK_VALID_AFTER
      );

      const sig = await offchainSigner.signMessage(arrayify(hash));

      const userOp = await fillAndSign(
        {
          ...userOp1,
          paymasterAndData: hexConcat([
            paymaster.address,
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            sig,
          ]),
        },
        accountOwner,
        entryPoint
      );

      const res = await entryPoint.callStatic
        .simulateValidation(userOp)
        .catch(simulationResultCatch);
      expect(res.returnInfo.sigFailed).to.be.false;
      expect(res.returnInfo.validAfter).to.be.equal(
        ethers.BigNumber.from(MOCK_VALID_AFTER)
      );
      expect(res.returnInfo.validUntil).to.be.equal(
        ethers.BigNumber.from(MOCK_VALID_UNTIL)
      );
    });

    it('should reject if not a whitelisted signature', async () => {
      const userOp2 = await fillAndSign(
        {
          sender: account.address,
          paymasterAndData: hexConcat([
            paymaster.address,
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            '0x' + '00'.repeat(65),
          ]),
          verificationGasLimit: 120000,
        },
        accountOwner,
        entryPoint
      );

      const hash = await paymaster.getHash(
        userOp2,
        MOCK_VALID_UNTIL,
        MOCK_VALID_AFTER
      );
      const sig = await offchainSigner.signMessage(arrayify(hash));

      const userOp = await fillAndSign(
        {
          ...userOp2,
          paymasterAndData: hexConcat([
            paymaster.address,
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            sig,
          ]),
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

      // offchain signer add itself as sponsor for wlaccount
      await paymaster.connect(offchainSigner).add(wlaccount.address);
      // check added correctly
      const check = await paymaster.check(
        offchainSigner.address,
        wlaccount.address
      );

      const userOp2 = await fillAndSign(
        {
          sender: wlaccount.address,
          paymasterAndData: hexConcat([
            paymaster.address,
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            '0x' + '00'.repeat(65),
          ]),
          verificationGasLimit: 120000,
        },
        wlaccOwner,
        entryPoint
      );

      const hash = await paymaster.getHash(
        userOp2,
        MOCK_VALID_UNTIL,
        MOCK_VALID_AFTER
      );
      const sig = await offchainSigner.signMessage(arrayify(hash));

      const userOp = await fillAndSign(
        {
          ...userOp2,
          paymasterAndData: hexConcat([
            paymaster.address,
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            sig,
          ]),
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
          paymasterAndData: hexConcat([
            paymaster.address,
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            '0x' + '00'.repeat(65),
          ]),
          verificationGasLimit: 120000,
        },
        wlaccOwner,
        entryPoint
      );

      const hash = await paymaster.getHash(
        userOp2,
        MOCK_VALID_UNTIL,
        MOCK_VALID_AFTER
      );

      const sig = await offchainSigner1.signMessage(arrayify(hash));

      const userOp = await fillAndSign(
        {
          ...userOp2,
          paymasterAndData: hexConcat([
            paymaster.address,
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            sig,
          ]),
        },
        wlaccOwner,
        entryPoint
      );

      const revert = await entryPoint.callStatic
        .simulateValidation(userOp)
        .catch((e) => {
          return e.message;
        });
      expect(revert).to.contain(
        'EtherspotPaymaster:: Sponsor paymaster funds too low'
      );
    });
  });

  describe('#depositFunds', () => {
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

      const context = defaultAbiCoder.encode(
        ['address', 'address'],
        [offchainSigner.address, account.address]
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
      const context = defaultAbiCoder.encode(
        ['address', 'address'],
        [offchainSigner.address, account.address]
      );
      await expect(
        intpaymaster
          .connect(offchainSigner)
          .$_postOp(SUCCESS_OP, context, GAS_COST)
      )
        .to.emit(intpaymaster, 'SponsorSuccessful')
        .withArgs(offchainSigner.address, account.address);
    });

    it('should emit event upon op code revert when sponsoring failed tx', async () => {
      const context = defaultAbiCoder.encode(
        ['address', 'address'],
        [offchainSigner.address, account.address]
      );
      await expect(
        intpaymaster
          .connect(offchainSigner)
          .$_postOp(FAIL_OP, context, GAS_COST)
      )
        .to.emit(intpaymaster, 'SponsorUnsuccessful')
        .withArgs(offchainSigner.address, account.address);
    });

    it('should not deduct funds from sponsor if user op fails validation', async () => {
      const init = await intpaymaster.checkSponsorFunds(offchainSigner.address);
      expect(init).to.equal(ethers.utils.parseEther('2'));

      const context = defaultAbiCoder.encode(
        ['address', 'address'],
        [offchainSigner.address, account.address]
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
