/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IModule,
  IModuleInterface,
} from "../../../../../erc7579-ref-impl/src/interfaces/IModule.sol/IModule";

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "typeID",
        type: "uint256",
      },
    ],
    name: "isModuleType",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "onInstall",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "onUninstall",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

export class IModule__factory {
  static readonly abi = _abi;
  static createInterface(): IModuleInterface {
    return new utils.Interface(_abi) as IModuleInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IModule {
    return new Contract(address, _abi, signerOrProvider) as IModule;
  }
}
