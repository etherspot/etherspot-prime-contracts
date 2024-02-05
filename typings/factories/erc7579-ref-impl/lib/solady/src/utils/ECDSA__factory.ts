/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../../common";
import type {
  ECDSA,
  ECDSAInterface,
} from "../../../../../../erc7579-ref-impl/lib/solady/src/utils/ECDSA";

const _abi = [
  {
    inputs: [],
    name: "InvalidSignature",
    type: "error",
  },
] as const;

const _bytecode =
  "0x60566037600b82828239805160001a607314602a57634e487b7160e01b600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea26469706673582212209e3a2d970421d2eba52d20d8475bf7d2e2709963478eb13fbe2d32774f42f55464736f6c63430008170033";

type ECDSAConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: ECDSAConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class ECDSA__factory extends ContractFactory {
  constructor(...args: ECDSAConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ECDSA> {
    return super.deploy(overrides || {}) as Promise<ECDSA>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): ECDSA {
    return super.attach(address) as ECDSA;
  }
  override connect(signer: Signer): ECDSA__factory {
    return super.connect(signer) as ECDSA__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ECDSAInterface {
    return new utils.Interface(_abi) as ECDSAInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): ECDSA {
    return new Contract(address, _abi, signerOrProvider) as ECDSA;
  }
}
