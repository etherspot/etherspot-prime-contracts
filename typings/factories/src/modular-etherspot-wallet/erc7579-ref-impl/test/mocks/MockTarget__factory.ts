/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../../common";
import type {
  MockTarget,
  MockTargetInterface,
} from "../../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockTarget";

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "setValue",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "value",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b50610168806100206000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c80633fa4f2451461003b5780635524107714610059575b600080fd5b610043610089565b60405161005091906100b9565b60405180910390f35b610073600480360381019061006e9190610105565b61008f565b60405161008091906100b9565b60405180910390f35b60005481565b600081600081905550819050919050565b6000819050919050565b6100b3816100a0565b82525050565b60006020820190506100ce60008301846100aa565b92915050565b600080fd5b6100e2816100a0565b81146100ed57600080fd5b50565b6000813590506100ff816100d9565b92915050565b60006020828403121561011b5761011a6100d4565b5b6000610129848285016100f0565b9150509291505056fea2646970667358221220267fd7d1fa47c39d1da51b0b201a66f0f965dc4f4f64fa5898dbd057dc6b7a0c64736f6c63430008170033";

type MockTargetConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: MockTargetConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class MockTarget__factory extends ContractFactory {
  constructor(...args: MockTargetConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<MockTarget> {
    return super.deploy(overrides || {}) as Promise<MockTarget>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): MockTarget {
    return super.attach(address) as MockTarget;
  }
  override connect(signer: Signer): MockTarget__factory {
    return super.connect(signer) as MockTarget__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MockTargetInterface {
    return new utils.Interface(_abi) as MockTargetInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MockTarget {
    return new Contract(address, _abi, signerOrProvider) as MockTarget;
  }
}
