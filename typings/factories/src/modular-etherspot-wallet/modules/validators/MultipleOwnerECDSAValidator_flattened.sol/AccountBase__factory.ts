/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../../common";
import type {
  AccountBase,
  AccountBaseInterface,
} from "../../../../../../src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator_flattened.sol/AccountBase";

const _abi = [
  {
    inputs: [],
    name: "AccountAccessUnauthorized",
    type: "error",
  },
  {
    inputs: [],
    name: "entryPoint",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x6080604052348015600f57600080fd5b50608680601d6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063b0d691fe14602d575b600080fd5b604080516f71727de22e5e9d8baf0edac6f37da032815290519081900360200190f3fea264697066735822122097357a3e4fea6778a49e572b1ee7cf479dd59c488cdd0c75408d5b1c2fa1154a64736f6c63430008170033";

type AccountBaseConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: AccountBaseConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class AccountBase__factory extends ContractFactory {
  constructor(...args: AccountBaseConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<AccountBase> {
    return super.deploy(overrides || {}) as Promise<AccountBase>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): AccountBase {
    return super.attach(address) as AccountBase;
  }
  override connect(signer: Signer): AccountBase__factory {
    return super.connect(signer) as AccountBase__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): AccountBaseInterface {
    return new utils.Interface(_abi) as AccountBaseInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): AccountBase {
    return new Contract(address, _abi, signerOrProvider) as AccountBase;
  }
}
