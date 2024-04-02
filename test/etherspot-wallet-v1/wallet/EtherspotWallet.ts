/* eslint-disable @typescript-eslint/camelcase */
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';
import { loadFixture, time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import {
  ERC1967Proxy__factory,
  TestUtil,
  TestUtil__factory,
} from '../../../account-abstraction/typechain';
import {
  EtherspotWallet,
  EtherspotWallet__factory,
  EtherspotWalletFactory,
  EtherspotWalletFactory__factory,
} from '../../../typings';
import {
  createAccountOwner,
  getBalance,
  ONE_ETH,
  HashZero,
  AddressZero,
  fund,
  createAddress,
  deployEntryPoint,
} from '../../../account-abstraction/test/testutils';
import { createEtherspotWallet, errorParse } from '../TestUtils';
import {
  fillUserOpDefaults,
  getUserOpHash,
  packUserOp,
  signUserOp,
  encodeUserOp,
} from '../../../account-abstraction/test/UserOp';
import { parseEther } from 'ethers/lib/utils';
import { UserOperation } from '../../../account-abstraction/test/UserOperation';

describe('EtherspotWallet', function () {
  let entryPoint: string;
  const ethersSigner = ethers.provider.getSigner();
  let accounts: string[];
  let testUtil: TestUtil;
  let accountFactory: EtherspotWalletFactory;
  let accountOwner: Wallet;

  before(async function () {
    entryPoint = await deployEntryPoint().then((e) => e.address);
    accounts = await ethers.provider.listAccounts();
    // ignore in geth.. this is just a sanity test. should be refactored to use a single-account mode..
    if (accounts.length < 2) this.skip();
    testUtil = await new TestUtil__factory(ethersSigner).deploy();
    accountOwner = createAccountOwner();

    accountFactory = await new EtherspotWalletFactory__factory(
      ethersSigner
    ).deploy(await ethersSigner.getAddress());
  });

  async function deployAndPrefund() {
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
    return { account };
  }

  it('should deploy wallet', async () => {
    const { proxy: account } = await createEtherspotWallet(
      ethers.provider.getSigner(),
      accounts[0],
      entryPoint
    );
    expect(await account.isOwner(accounts[0])).to.eq(true);
  });

  it('owner should be able to call execute', async () => {
    const { account } = await loadFixture(deployAndPrefund);
    await account.execute(accounts[2], ONE_ETH, '0x');
  });

  it('owner should be able to call executeBatch', async () => {
    const { account } = await loadFixture(deployAndPrefund);
    await account.executeBatch(
      [accounts[2], accounts[3]],
      [ONE_ETH, ONE_ETH],
      ['0x', '0x']
    );
  });

  it('a different owner should be able to call execute', async () => {
    const { account } = await loadFixture(deployAndPrefund);
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
    const encoded = encodeUserOp(op);
    const packed = packUserOp(op);
    expect(await testUtil.encodeUserOp(packed)).to.equal(encoded);
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
      const epAsSigner = await ethers.provider.getSigner(entryPointEoa);

      // cant use "EtherspotWalletFactory", since it attempts to increment nonce first
      const implementation = await new EtherspotWallet__factory(
        ethersSigner
      ).deploy(entryPointEoa, accountFactory.address);
      const proxy = await new ERC1967Proxy__factory(ethersSigner).deploy(
        implementation.address,
        '0x'
      );
      account = EtherspotWallet__factory.connect(proxy.address, epAsSigner);
      await account.initialize(accountOwner.address);

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
      const packedOp = packUserOp(userOp);
      const ret = await account.validateUserOp(
        packedOp,
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
      const packedOp = packUserOp(userOp);
      const deadline = await account.callStatic.validateUserOp(
        { ...packedOp, nonce: 1 },
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
        await ethers.provider.getSigner(entryPoint),
        accountOwner.address,
        entryPoint,
        accountFactory
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
      const packedOp = packUserOp(userOp);
      const ret = await account.validateUserOp(
        packedOp,
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
      const packedOp = packUserOp(userOp);
      const deadline = await account.callStatic.validateUserOp(
        { ...packedOp, nonce: 1 },
        userOpHash,
        0
      );
      expect(deadline).to.eq(1);
    });
  });

  describe('#isOwner', () => {
    it('should return true for valid owner', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      expect(await account.isOwner(accounts[0])).to.eq(true);
    });

    it('should return false for invalid owner', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      expect(await account.isOwner(accounts[1])).to.eq(false);
    });
  });

  describe('#addOwner', () => {
    it('should add a new owner (from owner)', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      expect(await account.isOwner(accounts[1])).to.eq(false);
      await account.addOwner(accounts[1]);
      expect(await account.isOwner(accounts[1])).to.eq(true);
    });

    it('should increment owner count', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      const preOwnerCount = await account.ownerCount();
      await account.addOwner(accounts[1]);
      await account.addOwner(accounts[2]);
      const postOwnerCount = await account.ownerCount();
      expect(postOwnerCount).to.eq(preOwnerCount.add(2));
    });

    it('should emit event on new owner added', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await expect(account.addOwner(accounts[1]))
        .to.emit(account, 'OwnerAdded')
        .withArgs(accounts[1]);
    });

    it('should trigger error if caller is not owner', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await expect(
        account.connect(ethers.provider.getSigner(2)).addOwner(accounts[3])
      ).to.be.revertedWith('ACL:: only owner');
    });

    it('should trigger error if already owner', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await expect(account.addOwner(accounts[0])).to.be.revertedWith(
        'ACL:: already owner'
      );
    });
  });

  describe('#removeOwner', () => {
    it('should remove an owner (from owner)', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await account.addOwner(accounts[1]);
      expect(await account.isOwner(accounts[1])).to.eq(true);
      await account.removeOwner(accounts[1]);
      expect(await account.isOwner(accounts[1])).to.eq(false);
    });

    it('should decrement owner count', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await account.addOwner(accounts[1]);
      await account.addOwner(accounts[2]);
      const preOwnerCount = await account.ownerCount();
      await account.removeOwner(accounts[1]);
      const postOwnerCount = await account.ownerCount();
      expect(postOwnerCount).to.eq(preOwnerCount.sub(1));
    });

    it('should emit event on removal of owner', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await account.addOwner(accounts[1]);
      expect(await account.isOwner(accounts[1])).to.eq(true);
      await expect(account.removeOwner(accounts[1]))
        .to.emit(account, 'OwnerRemoved')
        .withArgs(accounts[1]);
    });

    it('should trigger error caller is not owner', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await account.addOwner(accounts[1]);
      await expect(
        account.connect(ethers.provider.getSigner(2)).removeOwner(accounts[1])
      ).to.be.revertedWith('ACL:: only owner');
    });

    it('should trigger error if removing a non owner', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await expect(account.removeOwner(accounts[1])).to.be.revertedWith(
        'ACL:: non-existant owner'
      );
    });
  });

  describe('#isGuardian', () => {
    it('should return true for valid guardian', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await account.addGuardian(accounts[1]);
      expect(await account.isGuardian(accounts[1])).to.eq(true);
    });

    it('should return false for invalid guardian', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      expect(await account.isGuardian(accounts[1])).to.eq(false);
    });
  });

  describe('#addGuardian', () => {
    it('should add a new guardian', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      expect(await account.isGuardian(accounts[1])).to.eq(false);
      await account.addGuardian(accounts[1]);
      expect(await account.isGuardian(accounts[1])).to.eq(true);
    });

    it('should increment guardian count', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      const preGuardianCount = await account.guardianCount();
      await account.addGuardian(accounts[1]);
      await account.addGuardian(accounts[2]);
      const postGuardianCount = await account.guardianCount();
      expect(postGuardianCount).to.eq(preGuardianCount.add(2));
    });

    it('should trigger error on zero address', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await expect(account.addGuardian(AddressZero)).to.be.revertedWith(
        'ACL:: zero address'
      );
    });

    it('should trigger error on adding existing guardian', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await account.addGuardian(accounts[1]);
      await expect(account.addGuardian(accounts[1])).to.be.revertedWith(
        'ACL:: already guardian'
      );
    });

    it('should emit event on adding guardian', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await expect(account.addGuardian(accounts[1]))
        .to.emit(account, 'GuardianAdded')
        .withArgs(accounts[1]);
    });
  });

  describe('#removeGuardian', () => {
    it('should remove guardian', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      expect(await account.isGuardian(accounts[1])).to.eq(false);
      await account.addGuardian(accounts[1]);
      expect(await account.isGuardian(accounts[1])).to.eq(true);
      await account.removeGuardian(accounts[1]);
      expect(await account.isGuardian(accounts[1])).to.eq(false);
    });

    it('should decrement guardian count', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await account.addGuardian(accounts[1]);
      await account.addGuardian(accounts[2]);
      const preGuardianCount = await account.guardianCount();
      await account.removeGuardian(accounts[1]);
      const postGuardianCount = await account.guardianCount();
      expect(postGuardianCount).to.eq(preGuardianCount.sub(1));
    });

    it('should trigger error on removing non-existant guardian', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await expect(account.removeGuardian(accounts[1])).to.be.revertedWith(
        'ACL:: non-existant guardian'
      );
    });

    it('should emit event on removing guardian', async () => {
      const { account } = await loadFixture(deployAndPrefund);
      await account.addGuardian(accounts[1]);
      await expect(account.removeGuardian(accounts[1]))
        .to.emit(account, 'GuardianRemoved')
        .withArgs(accounts[1]);
    });
  });

  context('Proposing, cosigning and deleting', async () => {
    async function addGuardians() {
      const guardian1 = ethers.provider.getSigner(1);
      const guardian2 = ethers.provider.getSigner(2);
      const guardian3 = ethers.provider.getSigner(3);
      const guardian4 = ethers.provider.getSigner(4);
      const guardian1Addr = await guardian1.getAddress();
      const guardian2Addr = await guardian2.getAddress();
      const guardian3Addr = await guardian3.getAddress();
      const guardian4Addr = await guardian4.getAddress();
      const { account } = await loadFixture(deployAndPrefund);
      const preProposalId = await account.proposalId();
      await account.addGuardian(guardian1Addr);
      await account.addGuardian(guardian2Addr);
      await account.addGuardian(guardian3Addr);
      return {
        account,
        guardian1,
        guardian2,
        guardian3,
        guardian4,
        guardian1Addr,
        guardian2Addr,
        guardian3Addr,
        guardian4Addr,
        preProposalId,
      };
    }

    describe('#getProposal', async () => {
      it('should return proposal data for a specified proposal id', async () => {
        const { account, guardian1, guardian1Addr } = await loadFixture(
          addGuardians
        );
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const [newOwnerProposed, approvalCount, guardiansApproved] =
          await account.getProposal(await account.proposalId());
        expect(newOwnerProposed).to.eq(accounts[5]);
        expect(approvalCount).to.eq(1);
        expect(guardiansApproved[0]).to.eq(guardian1Addr);
      });

      it('should trigger error if specified proposal id is invalid', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await expect(
          account.connect(guardian1).guardianCosign()
        ).to.be.revertedWith('ACL:: invalid proposal id');
      });
    });

    describe('#guardianPropose', async () => {
      it('should allow guardian to propose a new owner', async () => {
        const { account, guardian1, guardian1Addr, preProposalId } =
          await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const proposalData = await account.getProposal(
          await account.proposalId()
        );
        expect(await account.proposalId()).to.eq(preProposalId.add(1));
        expect(proposalData.ownerProposed_).to.eq(accounts[5]);
        expect(proposalData.approvalCount_).to.eq(1);
        expect(proposalData.guardiansApproved_[0]).to.eq(guardian1Addr);
      });

      it('should emit event on submitting proposal', async () => {
        const { account, guardian1, guardian1Addr } = await loadFixture(
          addGuardians
        );
        await expect(account.connect(guardian1).guardianPropose(accounts[2]))
          .to.emit(account, 'ProposalSubmitted')
          .withArgs(1, accounts[2], guardian1Addr);
      });

      it('should only allow guardian to call (owner can just add new owner)', async () => {
        const { account } = await loadFixture(deployAndPrefund);
        await expect(account.guardianPropose(accounts[2])).to.be.revertedWith(
          'ACL:: only guardian'
        );
      });

      it('requires minimum of 3 guardians to propose a new owner', async () => {
        const guardian1 = ethers.provider.getSigner(1);
        const guardian2 = ethers.provider.getSigner(2);
        const guardian1Addr = await guardian1.getAddress();
        const guardian2Addr = await guardian2.getAddress();
        const { account } = await loadFixture(deployAndPrefund);
        await account.addGuardian(guardian1Addr);
        await account.addGuardian(guardian2Addr);
        const rev = await account
          .connect(guardian1)
          .guardianPropose(accounts[5])
          .catch((e) => {
            return errorParse(e.toString());
          });
        expect(rev).to.eq(
          'ACL:: not enough guardians to propose new owner (minimum 3)'
        );
      });

      it('should only allow one active proposal at a time and throw error if trying to add another', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        await expect(
          account.connect(guardian1).guardianPropose(accounts[6])
        ).to.be.revertedWith('ACL:: latest proposal not yet resolved');
      });

      it('should allow a new proposal after the previous one has been resolved (cosigned)', async () => {
        const { account, guardian1, guardian2 } = await loadFixture(
          addGuardians
        );
        await account.connect(guardian1).guardianPropose(accounts[5]);
        await account.connect(guardian2).guardianCosign();
        expect(await account.isOwner(accounts[5])).to.eq(true);
        expect(await account.connect(guardian1).guardianPropose(accounts[6])).to
          .not.be.reverted;
        const proposalData = await account.getProposal(
          await account.proposalId()
        );
        expect(proposalData.ownerProposed_).to.eq(accounts[6]);
        expect(proposalData.resolved_).to.eq(false);
      });

      it('should allow a new proposal after the previous one has been resolved (discarded)', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        await account.discardCurrentProposal();
        expect(await account.connect(guardian1).guardianPropose(accounts[6])).to
          .not.be.reverted;
        const proposalData = await account.getProposal(
          await account.proposalId()
        );
        expect(proposalData.ownerProposed_).to.eq(accounts[6]);
        expect(proposalData.resolved_).to.eq(false);
      });
    });

    describe('#guardianCosign', async () => {
      it('should allow guardian to cosign proposal and not reach quorum (emits event)', async () => {
        const { account, guardian1, guardian2, guardian4Addr } =
          await loadFixture(addGuardians);
        await account.addGuardian(guardian4Addr);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const proposalId = await account.proposalId();
        await expect(account.connect(guardian2).guardianCosign())
          .to.emit(account, 'QuorumNotReached')
          .withArgs(proposalId, accounts[5], 2);
      });

      it('should allow guardian to cosign proposal and reach quorum 2/3 (adds owner)', async () => {
        const { account, guardian1, guardian2 } = await loadFixture(
          addGuardians
        );
        await account.connect(guardian1).guardianPropose(accounts[5]);
        await account.connect(guardian2).guardianCosign();
        expect(await account.isOwner(accounts[5])).to.eq(true);
        const proposalData = await account.getProposal(1);
        expect(proposalData.ownerProposed_).to.eq(accounts[5]);
        expect(proposalData.resolved_).to.eq(true);
      });

      it('should allow guardian to cosign proposal and reach quorum 3/4 (adds owner)', async () => {
        const { account, guardian1, guardian2, guardian4, guardian4Addr } =
          await loadFixture(addGuardians);
        await account.addGuardian(guardian4Addr);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const proposalId = await account.proposalId();
        // sign with 2nd guardian (2/4)
        await expect(account.connect(guardian2).guardianCosign())
          .to.emit(account, 'QuorumNotReached')
          .withArgs(proposalId, accounts[5], 2);
        expect(await account.isOwner(accounts[5])).to.eq(false);
        // sign with 3rd guardian (3/4)
        await account.connect(guardian4).guardianCosign();
        expect(await account.isOwner(accounts[5])).to.eq(true);
      });

      it('should allow guardian to cosign proposal and reach quorum 3/5 (adds owner)', async () => {
        const { account, guardian1, guardian2, guardian4, guardian4Addr } =
          await loadFixture(addGuardians);
        await account.addGuardian(guardian4Addr);
        const guardian6 = ethers.provider.getSigner(6);
        const guardian6Addr = await guardian6.getAddress();
        await account.addGuardian(guardian6Addr);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const proposalId = await account.proposalId();
        // sign with 2nd guardian (2/5)
        await expect(account.connect(guardian2).guardianCosign())
          .to.emit(account, 'QuorumNotReached')
          .withArgs(proposalId, accounts[5], 2);
        expect(await account.isOwner(accounts[5])).to.eq(false);
        // sign with 3rd guardian (3/5)
        await account.connect(guardian4).guardianCosign();
        expect(await account.isOwner(accounts[5])).to.eq(true);
      });

      it('should allow guardian to cosign proposal and reach quorum 4/6 (adds owner)', async () => {
        const { account, guardian1, guardian2, guardian4, guardian4Addr } =
          await loadFixture(addGuardians);
        const guardian6 = ethers.provider.getSigner(6);
        const guardian7 = ethers.provider.getSigner(7);
        const guardian6Addr = await guardian6.getAddress();
        const guardian7Addr = await guardian7.getAddress();
        await account.addGuardian(guardian4Addr);
        await account.addGuardian(guardian6Addr);
        await account.addGuardian(guardian7Addr);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const proposalId = await account.proposalId();
        // sign with 2nd guardian (2/6)
        await expect(account.connect(guardian2).guardianCosign())
          .to.emit(account, 'QuorumNotReached')
          .withArgs(proposalId, accounts[5], 2);
        expect(await account.isOwner(accounts[5])).to.eq(false);
        // sign with 3rd guardian (3/6)
        await expect(account.connect(guardian4).guardianCosign())
          .to.emit(account, 'QuorumNotReached')
          .withArgs(proposalId, accounts[5], 3);
        expect(await account.isOwner(accounts[5])).to.eq(false);
        // sign with 4rd guardian (4/6)
        await account.connect(guardian6).guardianCosign();
        expect(await account.isOwner(accounts[5])).to.eq(true);
      });

      it('should only allow guardian to call (owner can just add new owner)', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[2]);
        await expect(account.guardianCosign()).to.be.revertedWith(
          'ACL:: only guardian'
        );
      });

      it("shouldn't allow guardians to approve proposal more than once", async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        await expect(account.guardianCosign()).to.be.revertedWith(
          'ACL:: only guardian'
        );
      });

      it('should throw error is invalid proposal id', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await expect(
          account.connect(guardian1).guardianCosign()
        ).to.be.revertedWith('ACL:: invalid proposal id');
      });
    });

    describe('#discardCurrentProposal', async () => {
      it('should discard current proposal (from owner)', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const pId = await account.proposalId();
        const proposalData = await account.getProposal(pId);
        // check proposal has been added correctly
        expect(proposalData.ownerProposed_).to.eq(accounts[5]);
        expect(proposalData.resolved_).to.eq(false);
        // discard current proposal
        await account.discardCurrentProposal();
        const discardProposalData = await account.getProposal(pId);
        expect(discardProposalData.ownerProposed_).to.eq(accounts[5]);
        expect(discardProposalData.resolved_).to.eq(true);
      });

      it('should discard current proposal (from guardian with default timelock (24hr))', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const pId = await account.proposalId();
        const proposalData = await account.getProposal(pId);
        // check proposal has been added correctly
        expect(proposalData.ownerProposed_).to.eq(accounts[5]);
        expect(proposalData.resolved_).to.eq(false);
        // discard current proposal
        await time.increase(86401);
        await account.connect(guardian1).discardCurrentProposal();
        const discardProposalData = await account.getProposal(pId);
        expect(discardProposalData.ownerProposed_).to.eq(accounts[5]);
        expect(discardProposalData.resolved_).to.eq(true);
      });

      it('should discard current proposal (from guardian with user defined timelock)', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const pId = await account.proposalId();
        const proposalData = await account.getProposal(pId);
        // check proposal has been added correctly
        expect(proposalData.ownerProposed_).to.eq(accounts[5]);
        expect(proposalData.resolved_).to.eq(false);
        // discard current proposal
        await account.changeProposalTimelock(43200);
        await time.increase(43201);
        await account.connect(guardian1).discardCurrentProposal();
        const discardProposalData = await account.getProposal(pId);
        expect(discardProposalData.ownerProposed_).to.eq(accounts[5]);
        expect(discardProposalData.resolved_).to.eq(true);
      });

      it('should emit event on proposal discard', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const pId = await account.proposalId();
        await expect(account.discardCurrentProposal())
          .to.emit(account, 'ProposalDiscarded')
          .withArgs(pId, accounts[0]);
      });

      it('should only allow guardian to call once proposal timelock is passed (default timelock)', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        await expect(
          account.connect(guardian1).discardCurrentProposal()
        ).to.be.revertedWith(
          'ACL:: guardian cannot discard proposal until timelock relased'
        );
      });

      it('should only allow guardian to call once proposal timelock is passed (user defined timelock)', async () => {
        const { account, guardian1 } = await loadFixture(addGuardians);
        await account.connect(guardian1).guardianPropose(accounts[5]);
        await account.changeProposalTimelock(4000);
        await expect(
          account.connect(guardian1).discardCurrentProposal()
        ).to.be.revertedWith(
          'ACL:: guardian cannot discard proposal until timelock relased'
        );
      });

      it('should not allow discarding of resolved proposal', async () => {
        const { account, guardian1, guardian2 } = await loadFixture(
          addGuardians
        );
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const pId = await account.proposalId();
        await account.connect(guardian2).guardianCosign();
        expect(await account.isOwner(accounts[5])).to.eq(true);
        const rev = await account
          .connect(accounts[0])
          .discardCurrentProposal()
          .catch((e) => {
            return errorParse(e.toString());
          });
        expect(rev).to.eq('ACL:: proposal already resolved');
      });

      it('should not allow cosigning a discarded proposal', async () => {
        const { account, guardian1, guardian2 } = await loadFixture(
          addGuardians
        );
        await account.connect(guardian1).guardianPropose(accounts[5]);
        const pId = await account.proposalId();
        await account.discardCurrentProposal();
        await expect(
          account.connect(guardian2).guardianCosign()
        ).to.be.revertedWith('ACL:: proposal already resolved');
      });
    });

    describe('upgrade wallet implementation revert check', async () => {
      it('should trigger error if implementation does not match proposed upgrade contract address', async () => {
        const implementation = await new EtherspotWallet__factory(
          ethersSigner
        ).deploy(entryPoint, accountFactory.address);
        await accountFactory.setImplementation(implementation.address);
        expect(implementation.address).to.eq(
          await accountFactory.accountImplementation()
        );
        const { proxy: account } = await createEtherspotWallet(
          ethers.provider.getSigner(),
          accounts[0],
          entryPoint,
          accountFactory
        );
        await expect(
          account.upgradeToAndCall(createAddress(), ethers.utils.hexlify('0x'))
        ).to.be.revertedWith(
          'EtherspotWallet:: upgrade implementation invalid'
        );
      });
      it('should trigger error if trying to upgrade to old implementation address', async () => {
        const implementation = await new EtherspotWallet__factory(
          ethersSigner
        ).deploy(entryPoint, accountFactory.address);
        await accountFactory.setImplementation(implementation.address);
        const { proxy: account } = await createEtherspotWallet(
          ethers.provider.getSigner(),
          accounts[0],
          entryPoint,
          accountFactory
        );
        const newImplementation = await new EtherspotWallet__factory(
          ethersSigner
        ).deploy(entryPoint, accountFactory.address);
        await accountFactory.setImplementation(newImplementation.address);
        const newerImplementation = await new EtherspotWallet__factory(
          ethersSigner
        ).deploy(entryPoint, accountFactory.address);
        await accountFactory.setImplementation(newerImplementation.address);
        await expect(
          account.upgradeToAndCall(
            newImplementation.address,
            ethers.utils.hexlify('0x')
          )
        ).to.be.revertedWith(
          'EtherspotWallet:: upgrade implementation invalid'
        );
      });
    });
  });
});
