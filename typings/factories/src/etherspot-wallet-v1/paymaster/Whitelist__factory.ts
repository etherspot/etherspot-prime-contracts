/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../common";
import type {
  Whitelist,
  WhitelistInterface,
} from "../../../../src/etherspot-wallet-v1/paymaster/Whitelist";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "paymaster",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address[]",
        name: "accounts",
        type: "address[]",
      },
    ],
    name: "AddedBatchToWhitelist",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "paymaster",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "AddedToWhitelist",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "paymaster",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address[]",
        name: "accounts",
        type: "address[]",
      },
    ],
    name: "RemovedBatchFromWhitelist",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "paymaster",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "RemovedFromWhitelist",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address[]",
        name: "_accounts",
        type: "address[]",
      },
    ],
    name: "addBatchToWhitelist",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
    ],
    name: "addToWhitelist",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_sponsor",
        type: "address",
      },
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
    ],
    name: "check",
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
        internalType: "address[]",
        name: "_accounts",
        type: "address[]",
      },
    ],
    name: "removeBatchFromWhitelist",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
    ],
    name: "removeFromWhitelist",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b50610b15806100206000396000f3fe608060405234801561001057600080fd5b50600436106100575760003560e01c8063123a6a821461005c5780638ab1d68114610078578063a3d19d8c14610094578063b3154db0146100b0578063e43252d7146100e0575b600080fd5b610076600480360381019061007191906106eb565b6100fc565b005b610092600480360381019061008d9190610796565b610165565b005b6100ae60048036038101906100a991906106eb565b6101cb565b005b6100ca60048036038101906100c591906107c3565b610234565b6040516100d7919061081e565b60405180910390f35b6100fa60048036038101906100f59190610796565b610248565b005b61010682826102ae565b81816040516101169291906108f6565b60405180910390203373ffffffffffffffffffffffffffffffffffffffff167f75dcdde27b71b9c529ae8b02072e1eeda244662d2d9c2effea5a1afb8fc913f360405160405180910390a35050565b61016e816102fc565b8073ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167fd288ab5da2e1f37cf384a1565a3f905ad289b092fbdd31950dbbfef148c04f8860405160405180910390a350565b6101d5828261044b565b81816040516101e59291906108f6565b60405180910390203373ffffffffffffffffffffffffffffffffffffffff167f6eabb183ad4385932735ae89018089a008c58e814451b618bc0dd0e7922f6d1360405160405180910390a35050565b60006102408383610499565b905092915050565b6102518161052c565b8073ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f0c4b48e75a1f7ab0a9a2f786b5d6c1f7789020403bff177fb54d46edb89ccc0060405160405180910390a350565b60005b828290508110156102f7576102ec8383838181106102d2576102d161090f565b5b90506020020160208101906102e79190610796565b6102fc565b8060010190506102b1565b505050565b600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff160361036b576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016103629061099b565b60405180910390fd5b6103753382610499565b6103b4576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016103ab90610a2d565b60405180910390fd5b60008060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff02191690831515021790555050565b60005b828290508110156104945761048983838381811061046f5761046e61090f565b5b90506020020160208101906104849190610796565b61052c565b80600101905061044e565b505050565b60008060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16905092915050565b600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff160361059b576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016105929061099b565b60405180910390fd5b6105a53382610499565b156105e5576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016105dc90610abf565b60405180910390fd5b60016000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff02191690831515021790555050565b600080fd5b600080fd5b600080fd5b600080fd5b600080fd5b60008083601f8401126106ab576106aa610686565b5b8235905067ffffffffffffffff8111156106c8576106c761068b565b5b6020830191508360208202830111156106e4576106e3610690565b5b9250929050565b600080602083850312156107025761070161067c565b5b600083013567ffffffffffffffff8111156107205761071f610681565b5b61072c85828601610695565b92509250509250929050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061076382610738565b9050919050565b61077381610758565b811461077e57600080fd5b50565b6000813590506107908161076a565b92915050565b6000602082840312156107ac576107ab61067c565b5b60006107ba84828501610781565b91505092915050565b600080604083850312156107da576107d961067c565b5b60006107e885828601610781565b92505060206107f985828601610781565b9150509250929050565b60008115159050919050565b61081881610803565b82525050565b6000602082019050610833600083018461080f565b92915050565b600081905092915050565b6000819050919050565b61085781610758565b82525050565b6000610869838361084e565b60208301905092915050565b60006108846020840184610781565b905092915050565b6000602082019050919050565b60006108a58385610839565b93506108b082610844565b8060005b858110156108e9576108c68284610875565b6108d0888261085d565b97506108db8361088c565b9250506001810190506108b4565b5085925050509392505050565b6000610903828486610899565b91508190509392505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b600082825260208201905092915050565b7f57686974656c6973743a3a205a65726f20616464726573730000000000000000600082015250565b600061098560188361093e565b91506109908261094f565b602082019050919050565b600060208201905081810360008301526109b481610978565b9050919050565b7f57686974656c6973743a3a204163636f756e74206973206e6f7420776869746560008201527f6c69737465640000000000000000000000000000000000000000000000000000602082015250565b6000610a1760268361093e565b9150610a22826109bb565b604082019050919050565b60006020820190508181036000830152610a4681610a0a565b9050919050565b7f57686974656c6973743a3a204163636f756e7420697320616c7265616479207760008201527f686974656c697374656400000000000000000000000000000000000000000000602082015250565b6000610aa9602a8361093e565b9150610ab482610a4d565b604082019050919050565b60006020820190508181036000830152610ad881610a9c565b905091905056fea2646970667358221220995cd1c56a8215429da00faf24c4b082abe3b4ed4e215d50a883bd62ab5a59cb64736f6c63430008170033";

type WhitelistConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: WhitelistConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class Whitelist__factory extends ContractFactory {
  constructor(...args: WhitelistConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<Whitelist> {
    return super.deploy(overrides || {}) as Promise<Whitelist>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): Whitelist {
    return super.attach(address) as Whitelist;
  }
  override connect(signer: Signer): Whitelist__factory {
    return super.connect(signer) as Whitelist__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): WhitelistInterface {
    return new utils.Interface(_abi) as WhitelistInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): Whitelist {
    return new Contract(address, _abi, signerOrProvider) as Whitelist;
  }
}
