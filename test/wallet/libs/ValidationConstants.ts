import { ethers } from 'hardhat';
import { expect } from 'chai';
import { ValidationConstants } from '../../../typings';
import { k256EncPack, hexSlicer4 } from '../../TestUtils';

describe('ValidationConstants', function () {
  let vc: ValidationConstants;

  beforeEach(async () => {
    const VC = await ethers.getContractFactory('ValidationConstants');
    vc = await VC.deploy();
  });

  it('should return contained constants - ERC777', async () => {
    const hash = k256EncPack('ERC777TokensRecipient');
    expect(await vc.ERC777_TOKENS_RECIPIENT_INTERFACE_HASH()).eq(hash);
  });

  it('should return contained constants - ERC1820', async () => {
    const hash = k256EncPack('ERC1820_ACCEPT_MAGIC');
    expect(await vc.ERC1820_ACCEPT_MAGIC()).eq(hash);
  });

  it('should return contained constants - ERC1271: valid message hash sig', async () => {
    const hash = hexSlicer4('isValidSignature(bytes32,bytes)');
    expect(await vc.ERC1271_VALID_MESSAGE_HASH_SIGNATURE()).eq(hash);
  });

  it('should return contained constants - ERC1271: valid message sig', async () => {
    const hash = hexSlicer4('isValidSignature(bytes,bytes)');
    expect(await vc.ERC1271_VALID_MESSAGE_SIGNATURE()).eq(hash);
  });

  it('should return contained constants - ERC1271: invalid sig', async () => {
    expect(await vc.ERC1271_INVALID_SIGNATURE()).eq('0xffffffff');
  });
});
