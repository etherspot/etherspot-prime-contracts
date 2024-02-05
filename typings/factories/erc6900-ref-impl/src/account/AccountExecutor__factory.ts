/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  AccountExecutor,
  AccountExecutorInterface,
} from "../../../../erc6900-ref-impl/src/account/AccountExecutor";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "plugin",
        type: "address",
      },
    ],
    name: "PluginExecutionDenied",
    type: "error",
  },
] as const;

export class AccountExecutor__factory {
  static readonly abi = _abi;
  static createInterface(): AccountExecutorInterface {
    return new utils.Interface(_abi) as AccountExecutorInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): AccountExecutor {
    return new Contract(address, _abi, signerOrProvider) as AccountExecutor;
  }
}
