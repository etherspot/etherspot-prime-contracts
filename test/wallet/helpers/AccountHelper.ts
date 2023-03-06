import { ethers } from 'hardhat';
import { Wallet } from 'ethers';
import { expect } from 'chai';
import {
  AccountRegistryMock,
  EtherspotWallet,
  EtherspotWalletFactory,
} from '../../../typings';
import { k256EncPack, getMethodSig } from '../../TestUtils';
import {
  createAccountOwner,
  createEtherspotWallet,
  fund,
} from '../../aa-4337/helpers/testutils';

describe('AccountHelper', function () {
  const entryPoint = '0x'.padEnd(42, '2');
  let reg: AccountRegistryMock;
  let etherspotWalletFactory: EtherspotWalletFactory;
  let account: EtherspotWallet;
  let accounts: string[];
  let accountOwner: Wallet;
  let invalidOwner: Wallet;
  const ethersSigner = ethers.provider.getSigner();

  const ERC777_TKNS_RECIPIENT_IFACE_HASH = k256EncPack('ERC777TokensRecipient');
  const ERC1820_ACCEPT_MAGIC = k256EncPack('ERC1820_ACCEPT_MAGIC');
  const ERC1271_INVALID_SIGNATURE = '0xffffffff';
  const INVALID_RETURN = ethers.utils.hexZeroPad(ethers.utils.hexlify(0), 32);

  beforeEach(async () => {
    accounts = await ethers.provider.listAccounts();
    accountOwner = createAccountOwner();
    invalidOwner = createAccountOwner();
    await fund(accountOwner.address);
    const REG = await ethers.getContractFactory('AccountRegistryMock');
    reg = await REG.connect(accountOwner).deploy();
    ({ proxy: account, accountFactory: etherspotWalletFactory } =
      await createEtherspotWallet(
        ethersSigner,
        await accountOwner.getAddress(),
        entryPoint,
        reg.address
      ));
    await fund(account);
  });

  describe('canImplementInterfaceForAddress', async () => {
    it('should return ERC1820 accept magic', async () => {
      expect(
        await account.canImplementInterfaceForAddress(
          ERC777_TKNS_RECIPIENT_IFACE_HASH,
          account.address
        )
      ).eq(ERC1820_ACCEPT_MAGIC);
    });
    it('should return nothing if incorrect params', async () => {
      expect(
        await account.canImplementInterfaceForAddress(
          ERC1820_ACCEPT_MAGIC,
          account.address
        )
      ).eq(INVALID_RETURN);
      expect(
        await account.canImplementInterfaceForAddress(
          ERC777_TKNS_RECIPIENT_IFACE_HASH,
          accountOwner.address
        )
      ).eq(INVALID_RETURN);
    });
  });

  describe('onERC721Received', async () => {
    it('should return correct interface hash', async () => {
      expect(
        await account.onERC721Received(
          ethers.Wallet.createRandom().address,
          ethers.Wallet.createRandom().address,
          1,
          '0x'
        )
      ).eq(getMethodSig('onERC721Received(address,address,uint256,bytes)'));
    });
  });

  describe('onERC1155Received', async () => {
    it('should return correct interface hash', async () => {
      expect(
        await account.onERC1155Received(
          ethers.Wallet.createRandom().address,
          ethers.Wallet.createRandom().address,
          1,
          2,
          '0x'
        )
      ).eq(
        getMethodSig('onERC1155Received(address,address,uint256,uint256,bytes)')
      );
    });
  });

  describe('tokensReceived', async () => {
    it('should return empty result', async () => {
      const tx = await account.tokensReceived(
        ethers.Wallet.createRandom().address,
        ethers.Wallet.createRandom().address,
        ethers.Wallet.createRandom().address,
        1,
        '0x',
        '0x'
      );
      return expect(Promise.resolve(tx)).to.eventually.equal([]);
    });
  });

  describe('isValidAccountSignature', async () => {
    it('expect to return magic hash on valid sig', async () => {
      await reg.mockAccountOwners(account.address, [accountOwner.address]);
      const message = 'test message';
      const signature = await accountOwner.signMessage(message);

      expect(
        await account['isValidSignature(bytes32,bytes)'](
          ethers.utils.hashMessage(message),
          signature
        )
      ).eq(
        getMethodSig(
          'isValidSignature(bytes32,bytes)' //
        )
      );

      // TODO: fix test as currently reverting with Sol panic code 0x11 (overflow/underflow)
      // expect(
      //   await account['isValidSignature(bytes,bytes)'](
      //     ethers.utils.formatBytes32String(message),
      //     signature
      //   )
      // ).eq(
      //   getMethodSig(
      //     'isValidSignature(bytes,bytes)' //
      //   )
      // );
    });
    it('expect to return 0xffffffff on invalid sig', async () => {
      const message = 'test message';
      const signature = await invalidOwner.signMessage(message);

      expect(
        await account['isValidSignature(bytes32,bytes)'](
          ethers.utils.hashMessage(message),
          signature
        )
      ).eq(ERC1271_INVALID_SIGNATURE);

      // TODO: fix test as currently reverting with Sol panic code 0x11 (overflow/underflow)
      // expect(
      //   await account['isValidSignature(bytes,bytes)'](
      // ethers.utils.formatBytes32String(message),
      //     signature
      //   )
      // ).eq(ERC1271_INVALID_SIGNATURE);
    });
  });
});
