/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../../common";
import type {
  SentinelListLib,
  SentinelListLibInterface,
} from "../../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/SentinelList.sol/SentinelListLib";

const _abi = [
  {
    inputs: [],
    name: "LinkedList_AlreadyInitialized",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "entry",
        type: "address",
      },
    ],
    name: "LinkedList_EntryAlreadyInList",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "entry",
        type: "address",
      },
    ],
    name: "LinkedList_InvalidEntry",
    type: "error",
  },
  {
    inputs: [],
    name: "LinkedList_InvalidPage",
    type: "error",
  },
] as const;

const _bytecode =
  "0x60566050600b82828239805160001a6073146043577f4e487b7100000000000000000000000000000000000000000000000000000000600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea2646970667358221220580f8190f6feadde393a6c0b81c390539a796123a71eccfd23821561cbdeb23e64736f6c63430008170033";

type SentinelListLibConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: SentinelListLibConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class SentinelListLib__factory extends ContractFactory {
  constructor(...args: SentinelListLibConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<SentinelListLib> {
    return super.deploy(overrides || {}) as Promise<SentinelListLib>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): SentinelListLib {
    return super.attach(address) as SentinelListLib;
  }
  override connect(signer: Signer): SentinelListLib__factory {
    return super.connect(signer) as SentinelListLib__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): SentinelListLibInterface {
    return new utils.Interface(_abi) as SentinelListLibInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): SentinelListLib {
    return new Contract(address, _abi, signerOrProvider) as SentinelListLib;
  }
}
