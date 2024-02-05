/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IPluginExecutor,
  IPluginExecutorInterface,
} from "../../../../erc6900-ref-impl/src/interfaces/IPluginExecutor";

const _abi = [
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "executeFromPlugin",
    outputs: [
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "target",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "executeFromPluginExternal",
    outputs: [
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    stateMutability: "payable",
    type: "function",
  },
] as const;

export class IPluginExecutor__factory {
  static readonly abi = _abi;
  static createInterface(): IPluginExecutorInterface {
    return new utils.Interface(_abi) as IPluginExecutorInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IPluginExecutor {
    return new Contract(address, _abi, signerOrProvider) as IPluginExecutor;
  }
}
