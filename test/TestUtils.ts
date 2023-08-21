import { ethers } from 'hardhat';
import { Signer } from 'ethers';
import {
  EtherspotWallet,
  EtherspotWalletFactory__factory,
  EtherspotWallet__factory,
  EtherspotWalletFactory,
} from '../typings';

export function k256EncPack(_string: string) {
  return ethers.utils.solidityKeccak256(['string'], [_string]);
}

export function hexSlicer4(_string: string) {
  return ethers.utils.hexDataSlice(k256EncPack(_string), 0, 4);
}

export function getMethodSig(method: string): string {
  return ethers.utils.id(method).slice(0, 10);
}

// Deploys an implementation and a proxy pointing to this implementation
export async function createEtherspotWallet(
  ethersSigner: Signer,
  accountOwner: string,
  entryPoint: string,
  _factory?: EtherspotWalletFactory
): Promise<{
  proxy: EtherspotWallet;
  accountFactory: EtherspotWalletFactory;
  implementation: string;
}> {
  const accountFactory =
    _factory ??
    (await new EtherspotWalletFactory__factory(ethersSigner).deploy(
      await ethersSigner.getAddress()
    ));
  const impl = await new EtherspotWallet__factory(ethersSigner).deploy(
    entryPoint,
    accountFactory.address
  );
  await accountFactory.setImplementation(impl.address);
  const implementation = await accountFactory.accountImplementation();

  await accountFactory.createAccount(accountOwner, 0);
  const accountAddress = await accountFactory.getAddress(accountOwner, 0);
  const proxy = EtherspotWallet__factory.connect(accountAddress, ethersSigner);
  return {
    implementation,
    accountFactory,
    proxy,
  };
}

export function errorParse(error: string) {
  const pattern = /reverted with reason string '(.+?)'/;
  const match = error.match(pattern);

  if (match && match.length > 1) {
    const extractedSubstring = match[1];
    return extractedSubstring;
  } else {
    return 'Substring not found';
  }
}
