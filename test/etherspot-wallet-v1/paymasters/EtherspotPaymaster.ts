/* eslint-disable @typescript-eslint/camelcase */
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { EntryPoint } from '../../../account-abstraction/typechain';
import {
  EtherspotWallet,
  EtherspotPaymaster,
  EtherspotPaymaster__factory,
} from '../../../typings';
import {
  AddressZero,
  createAccountOwner,
  createAddress,
  deployEntryPoint,
  decodeRevertReason,
  packPaymasterData,
  parseValidationData,
} from '../../../account-abstraction/test/testutils';
import { createEtherspotWallet, errorParse } from '../TestUtils';
import {
  DefaultsForUserOp,
  fillAndSign,
  fillSignAndPack,
  packUserOp,
  simulateValidation,
} from '../../../account-abstraction/test/UserOp';
import {
  arrayify,
  defaultAbiCoder,
  hexConcat,
  parseEther,
} from 'ethers/lib/utils';
import { PackedUserOperation } from '../../../account-abstraction/test/UserOperation';

const MOCK_VALID_UNTIL = '0x00000000deadbeef';
const MOCK_VALID_AFTER = '0x0000000000001234';
const MOCK_SIG = '0x1234';

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

  before(async () => {
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
      const paymasterAndData = packPaymasterData(
        paymaster.address,
        DefaultsForUserOp.paymasterVerificationGasLimit,
        DefaultsForUserOp.paymasterPostOpGasLimit,
        hexConcat([
          defaultAbiCoder.encode(
            ['uint48', 'uint48'],
            [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
          ),
          MOCK_SIG,
        ])
      );
      console.log(paymasterAndData);
      const res = await paymaster.parsePaymasterAndData(paymasterAndData);
      // console.log('MOCK_VALID_UNTIL, MOCK_VALID_AFTER', MOCK_VALID_UNTIL, MOCK_VALID_AFTER)
      // console.log('validUntil after', res.validUntil, res.validAfter)
      // console.log('MOCK SIG', MOCK_SIG)
      // console.log('sig', res.signature)
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
      await paymaster.connect(acc1).addToWhitelist(acc2.address);
      expect(await paymaster.check(acc1.address, acc2.address)).to.be.true;
      await paymaster.connect(acc1).removeFromWhitelist(acc2.address);
      expect(await paymaster.check(acc1.address, acc2.address)).to.be.false;
    });
  });

  describe('#validatePaymasterUserOp', () => {
    it('should reject on no signature', async () => {
      const userOp = await fillSignAndPack(
        {
          sender: account.address,
          paymaster: paymaster.address,
          paymasterData: hexConcat([
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            '0x1234',
          ]),
        },
        accountOwner,
        entryPoint
      );
      expect(
        await simulateValidation(userOp, entryPoint.address).catch((e) =>
          decodeRevertReason(e)
        )
      ).to.include('invalid signature length in paymasterAndData');
    });

    it('should reject on invalid signature', async () => {
      const userOp = await fillSignAndPack(
        {
          sender: account.address,
          paymaster: paymaster.address,
          paymasterData: hexConcat([
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
      expect(
        await simulateValidation(userOp, entryPoint.address).catch((e) =>
          decodeRevertReason(e)
        )
      ).to.include('ECDSAInvalidSignature');
    });

    describe('with wrong signature', () => {
      let wrongSigUserOp: PackedUserOperation;
      const beneficiaryAddress = createAddress();
      before(async () => {
        const sig = await offchainSigner.signMessage(arrayify('0xdead'));
        wrongSigUserOp = await fillSignAndPack(
          {
            sender: account.address,
            paymaster: paymaster.address,
            paymasterData: hexConcat([
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
        const ret = await simulateValidation(
          wrongSigUserOp,
          entryPoint.address
        );
        expect(
          parseValidationData(ret.returnInfo.paymasterValidationData).aggregator
        ).to.match(/0x0*1$/);
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
      await paymaster.connect(offchainSigner).addToWhitelist(account.address);
      await paymaster
        .connect(offchainSigner)
        .depositFunds({ value: ethers.utils.parseEther('2.0') });

      const userOp1 = await fillAndSign(
        {
          sender: account.address,
          paymaster: paymaster.address,
          paymasterData: hexConcat([
            defaultAbiCoder.encode(
              ['uint48', 'uint48'],
              [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]
            ),
            '0x' + '00'.repeat(65),
          ]),
        },
        accountOwner,
        entryPoint
      );
      const hash = await paymaster.getHash(
        packUserOp(userOp1),
        MOCK_VALID_UNTIL,
        MOCK_VALID_AFTER
      );
      const sig = await offchainSigner.signMessage(arrayify(hash));
      const userOp = await fillSignAndPack(
        {
          ...userOp1,
          paymaster: paymaster.address,
          paymasterData: hexConcat([
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
      const res = await simulateValidation(userOp, entryPoint.address);
      const validationData = parseValidationData(
        res.returnInfo.paymasterValidationData
      );
      expect(validationData).to.eql({
        aggregator: AddressZero,
        validAfter: parseInt(MOCK_VALID_AFTER),
        validUntil: parseInt(MOCK_VALID_UNTIL),
      });
    });

    it('should reject if not a whitelisted signature', async () => {
      await paymaster
        .connect(offchainSigner)
        .depositFunds({ value: ethers.utils.parseEther('2.0') });

      const userOp2 = await fillAndSign(
        {
          sender: wlaccount.address,
          paymaster: paymaster.address,
          paymasterData: hexConcat([
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
        packUserOp(userOp2),
        MOCK_VALID_UNTIL,
        MOCK_VALID_AFTER
      );
      const sig = await offchainSigner.signMessage(arrayify(hash));

      const userOp = await fillSignAndPack(
        {
          ...userOp2,
          paymaster: paymaster.address,
          paymasterData: hexConcat([
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

      const res = await simulateValidation(userOp, entryPoint.address);

      expect(
        parseValidationData(res.returnInfo.paymasterValidationData).aggregator
      ).to.match(/0x0*1$/);
    });

    it('succeeds if whitelisted signature', async () => {
      await paymaster
        .connect(offchainSigner)
        .depositFunds({ value: ethers.utils.parseEther('2.0') });

      // offchain signer add itself as sponsor for wlaccount
      await paymaster.connect(offchainSigner).addToWhitelist(wlaccount.address);
      // check added correctly
      const check = await paymaster.check(
        offchainSigner.address,
        wlaccount.address
      );

      const userOp2 = await fillAndSign(
        {
          sender: wlaccount.address,
          paymaster: paymaster.address,
          paymasterData: hexConcat([
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
        packUserOp(userOp2),
        MOCK_VALID_UNTIL,
        MOCK_VALID_AFTER
      );
      const sig = await offchainSigner.signMessage(arrayify(hash));

      const userOp = await fillSignAndPack(
        {
          ...userOp2,
          paymaster: paymaster.address,
          paymasterData: hexConcat([
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

      const res = await simulateValidation(userOp, entryPoint.address);
      const validationData = parseValidationData(
        res.returnInfo.paymasterValidationData
      );
      expect(validationData).to.eql({
        aggregator: AddressZero,
        validAfter: parseInt(MOCK_VALID_AFTER),
        validUntil: parseInt(MOCK_VALID_UNTIL),
      });
    });

    it('error thrown if sponsor balance too low', async () => {
      await paymaster
        .connect(offchainSigner)
        .depositFunds({ value: ethers.utils.parseEther('2.0') });
      await paymaster
        .connect(offchainSigner1)
        .addToWhitelist(wlaccount.address);
      const userOp2 = await fillAndSign(
        {
          sender: wlaccount.address,
          paymaster: paymaster.address,
          paymasterData: hexConcat([
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
        packUserOp(userOp2),
        MOCK_VALID_UNTIL,
        MOCK_VALID_AFTER
      );

      const sig = await offchainSigner1.signMessage(arrayify(hash));

      const userOp = await fillSignAndPack(
        {
          ...userOp2,
          paymaster: paymaster.address,
          paymasterData: hexConcat([
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

      expect(
        await simulateValidation(userOp, entryPoint.address).catch((e) =>
          decodeRevertReason(e)
        )
      ).to.contain('EtherspotPaymaster:: Sponsor paymaster funds too low');
    });
  });

  describe('#depositFunds', () => {
    it('should succeed in depositing funds', async () => {
      const init = await paymaster.getSponsorBalance(offchainSigner.address);
      await expect(() =>
        paymaster
          .connect(offchainSigner)
          .depositFunds({ value: ethers.utils.parseEther('2.0') })
      ).to.changeEtherBalance(offchainSigner, ethers.utils.parseEther('-2.0'));
      const post = await paymaster.getSponsorBalance(offchainSigner.address);
      expect(post.sub(init)).to.equal(ethers.utils.parseEther('2.0'));
    });
  });

  describe('#withdrawFunds', () => {
    it('should succeed in withdrawing funds', async () => {
      await paymaster
        .connect(offchainSigner)
        .depositFunds({ value: ethers.utils.parseEther('2.0') });
      const pre = await paymaster.getSponsorBalance(offchainSigner.address);
      await expect(() =>
        paymaster
          .connect(offchainSigner)
          .withdrawFunds(ethers.utils.parseEther('1.0'))
      ).to.changeEtherBalance(offchainSigner, ethers.utils.parseEther('1.0'));
      const post = await paymaster.getSponsorBalance(offchainSigner.address);
      expect(pre.sub(post)).to.equal(ethers.utils.parseEther('1.0'));
    });

    it('should throw error when amount is greater than sponsor deposited balance', async () => {
      await paymaster
        .connect(offchainSigner)
        .withdrawFunds(ethers.utils.parseEther('1.0'))
        .catch((e) => {
          const error = errorParse(e.toString());
          expect(error).to.equal(
            'EtherspotPaymaster:: not enough deposited funds'
          );
        });
    });
  });
});
