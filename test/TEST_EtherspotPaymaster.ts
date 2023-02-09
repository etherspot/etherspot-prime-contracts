/* eslint-disable @typescript-eslint/camelcase */
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import {
  EtherspotAccount,
  EntryPoint,
  EtherspotPaymaster,
  EtherspotPaymaster__factory,
} from '../typechain-types';
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
  let accOwner: Wallet;
  const ethersSigner = ethers.provider.getSigner();
  let account: EtherspotAccount;
  let acc1: EtherspotAccount;
  let offchainSigner: Wallet;
  let paym: any;
  let acc: any;
  let paymaster: EtherspotPaymaster;

  beforeEach(async () => {
    [paym, acc] = await ethers.getSigners();

    this.timeout(20000);
    entryPoint = await deployEntryPoint();

    offchainSigner = createAccountOwner();
    accountOwner = createAccountOwner();
    accOwner = createAccountOwner();

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
    ({ proxy: acc1 } = await createAccount(
      ethersSigner,
      accOwner.address,
      entryPoint.address
    ));
  });

  describe('#addToWhitelist', () => {
    it('should revert if added account is address(0)', async () => {
      await expect(paymaster.addToWhitelist(AddressZero)).to.be.revertedWith(
        'EtherspotPaymaster:: Account cannot be address(0)'
      );
    });
    it('should revert if trying to whitelist and already whitelisted account', async () => {
      await paymaster.addToWhitelist(account.address);
      await expect(
        paymaster.addToWhitelist(account.address)
      ).to.be.revertedWith(
        'EtherspotPaymaster:: Account is already whitelisted'
      );
    });
    it('should successfully whitelist and account', async () => {
      await expect(paymaster.connect(paym).addToWhitelist(account.address))
        .to.emit(paymaster, 'AddedToWhitelist')
        .withArgs(paym.address, account.address);
    });
  });

  describe('#removeFromWhitelist', () => {
    it('should revert if added account is address(0)', async () => {
      await expect(
        paymaster.removeFromWhitelist(AddressZero)
      ).to.be.revertedWith('EtherspotPaymaster:: Account cannot be address(0)');
    });
    it('should revert if trying to remove account that is not whitelisted', async () => {
      await expect(
        paymaster.connect(paym).removeFromWhitelist(account.address)
      ).to.be.revertedWith('EtherspotPaymaster:: Account is not whitelisted');
    });
    it('should successfully remove whitelisted account', async () => {
      const tx = await paymaster.connect(paym).addToWhitelist(account.address);
      tx.wait(2);
      await expect(paymaster.connect(paym).removeFromWhitelist(account.address))
        .to.emit(paymaster, 'RemovedFromWhitelist')
        .withArgs(paym.address, account.address);
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
      await entryPoint.callStatic
        .simulateValidation(userOp)
        .catch(simulationResultCatch);
    });

    it('succeed with whitelisted signature', async () => {
      await paymaster.connect(accOwner).addToWhitelist(account.address);

      const userOp2 = await fillAndSign(
        {
          sender: acc1.address,
        },
        accOwner,
        entryPoint
      );
      const hash = await paymaster.getHash(userOp2);
      const sig = await accountOwner.signMessage(arrayify(hash));
      const userOp = await fillAndSign(
        {
          ...userOp2,
          paymasterAndData: hexConcat([paymaster.address, sig]),
        },
        accOwner,
        entryPoint
      );
      await entryPoint.callStatic
        .simulateValidation(userOp)
        .catch(simulationResultCatch);
    });
  });
});
