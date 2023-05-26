import { ethers } from 'hardhat';
import { Signer } from 'ethers';
import {
  EtherspotWallet,
  EtherspotWalletFactory__factory,
  EtherspotWallet__factory,
  EtherspotWalletFactory,
  ProxyFactory__factory,
  ProxyFactory
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
    (await new EtherspotWalletFactory__factory(ethersSigner).deploy());
  const implementation = await accountFactory.accountImplementation();
  await accountFactory.createAccount(entryPoint, accountOwner, 0);
  const accountAddress = await accountFactory.getAddress(
    entryPoint,
    accountOwner,
    0
  );
  const proxy = EtherspotWallet__factory.connect(accountAddress, ethersSigner);
  return {
    implementation,
    accountFactory,
    proxy,
  };
}
