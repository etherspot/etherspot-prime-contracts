import { ethers } from 'hardhat';
import { BigNumber, ContractReceipt, providers } from 'ethers';

export function k256EncPack(_string: string) {
  return ethers.utils.solidityKeccak256(['string'], [_string]);
}

export function hexSlicer4(_string: string) {
  return ethers.utils.hexDataSlice(k256EncPack(_string), 0, 4);
}

export function getMethodSig(method: string): string {
  return ethers.utils.id(method).slice(0, 10);
}
