/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  TestOracle,
  TestOracleInterface,
} from "../../../src/test/TestOracle";

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "ethOutput",
        type: "uint256",
      },
    ],
    name: "getTokenValueOfEth",
    outputs: [
      {
        internalType: "uint256",
        name: "tokenInput",
        type: "uint256",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b50610206806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063d1eca9cf14610030575b600080fd5b61004a600480360381019061004591906100f0565b610060565b604051610057919061012c565b60405180910390f35b60006100766704dd74a7afda5f7560c01b6100b2565b61008a67fc6293fa4acafdb660c01b6100b2565b61009e67e086bbc75342888c60c01b6100b2565b6002826100ab9190610176565b9050919050565b50565b600080fd5b6000819050919050565b6100cd816100ba565b81146100d857600080fd5b50565b6000813590506100ea816100c4565b92915050565b600060208284031215610106576101056100b5565b5b6000610114848285016100db565b91505092915050565b610126816100ba565b82525050565b6000602082019050610141600083018461011d565b92915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000610181826100ba565b915061018c836100ba565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff04831182151516156101c5576101c4610147565b5b82820290509291505056fea2646970667358221220887c67c0077b2d578e58f73f6f00f51648b9478f1379fc2e5c59b72d589b845e64736f6c634300080c0033";

type TestOracleConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: TestOracleConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class TestOracle__factory extends ContractFactory {
  constructor(...args: TestOracleConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<TestOracle> {
    return super.deploy(overrides || {}) as Promise<TestOracle>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): TestOracle {
    return super.attach(address) as TestOracle;
  }
  override connect(signer: Signer): TestOracle__factory {
    return super.connect(signer) as TestOracle__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): TestOracleInterface {
    return new utils.Interface(_abi) as TestOracleInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): TestOracle {
    return new Contract(address, _abi, signerOrProvider) as TestOracle;
  }
}
