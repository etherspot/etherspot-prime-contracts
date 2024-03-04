/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../common";
import type {
  EtherspotWallet7579Factory,
  EtherspotWallet7579FactoryInterface,
} from "../../../../src/ERC7579/wallet/EtherspotWallet7579Factory";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_ewImplementation",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "_salt",
        type: "bytes32",
      },
      {
        internalType: "bytes",
        name: "initCode",
        type: "bytes",
      },
    ],
    name: "_getSalt",
    outputs: [
      {
        internalType: "bytes32",
        name: "salt",
        type: "bytes32",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "salt",
        type: "bytes32",
      },
      {
        internalType: "bytes",
        name: "initCode",
        type: "bytes",
      },
    ],
    name: "createAccount",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "salt",
        type: "bytes32",
      },
      {
        internalType: "bytes",
        name: "initcode",
        type: "bytes",
      },
    ],
    name: "getAddress",
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
  {
    inputs: [],
    name: "implementation",
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
  "0x60a060405234801561001057600080fd5b5060405161054438038061054483398101604081905261002f91610040565b6001600160a01b0316608052610070565b60006020828403121561005257600080fd5b81516001600160a01b038116811461006957600080fd5b9392505050565b6080516104ac61009860003960008181608901528181610141015261018901526104ac6000f3fe60806040526004361061003f5760003560e01c806356c717f5146100445780635c60da1b14610077578063d959fd0e146100c3578063f8a59370146100e3575b600080fd5b34801561005057600080fd5b5061006461005f3660046103b1565b6100f6565b6040519081526020015b60405180910390f35b34801561008357600080fd5b506100ab7f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200161006e565b3480156100cf57600080fd5b506100ab6100de3660046103b1565b61012c565b6100ab6100f13660046103b1565b610170565b600083838360405160200161010d9392919061042d565b6040516020818303038152906040528051906020012090509392505050565b60008061013a8585856100f6565b90506101677f00000000000000000000000000000000000000000000000000000000000000008230610222565b95945050505050565b60008061017e8585856100f6565b90506000806101ae347f0000000000000000000000000000000000000000000000000000000000000000856102ab565b915091508161021857604051634b6a141960e01b81526001600160a01b03821690634b6a1419906101e59089908990600401610447565b600060405180830381600087803b1580156101ff57600080fd5b505af1158015610213573d6000803e3d6000fd5b505050505b9695505050505050565b60008061029e85604080517fcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f360609081527f5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e20768352616009602052601e9390935268603d3d8160223d3973600a52605f6021209152600090915290565b905061016781858561038f565b6000806040517fcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f36060527f5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e207660405261600960205284601e5268603d3d8160223d3973600a52605f60212060358201523060581b815260ff8153836015820152605581209150813b6103575783605f602188f59150816103525763301164256000526004601cfd5b61037d565b60019250851561037d5760003860003889865af161037d5763b12d13eb6000526004601cfd5b80604052506000606052935093915050565b600060ff60005350603592835260601b60015260155260556000908120915290565b6000806000604084860312156103c657600080fd5b83359250602084013567ffffffffffffffff808211156103e557600080fd5b818601915086601f8301126103f957600080fd5b81358181111561040857600080fd5b87602082850101111561041a57600080fd5b6020830194508093505050509250925092565b838152818360208301376000910160200190815292915050565b60208152816020820152818360408301376000818301604090810191909152601f909201601f1916010191905056fea2646970667358221220a61ce66e1d571004e70201d8429d05f49ab0d1c9fa70aadd2e986bf67745bbe764736f6c63430008170033";

type EtherspotWallet7579FactoryConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: EtherspotWallet7579FactoryConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class EtherspotWallet7579Factory__factory extends ContractFactory {
  constructor(...args: EtherspotWallet7579FactoryConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    _ewImplementation: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<EtherspotWallet7579Factory> {
    return super.deploy(
      _ewImplementation,
      overrides || {}
    ) as Promise<EtherspotWallet7579Factory>;
  }
  override getDeployTransaction(
    _ewImplementation: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(_ewImplementation, overrides || {});
  }
  override attach(address: string): EtherspotWallet7579Factory {
    return super.attach(address) as EtherspotWallet7579Factory;
  }
  override connect(signer: Signer): EtherspotWallet7579Factory__factory {
    return super.connect(signer) as EtherspotWallet7579Factory__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): EtherspotWallet7579FactoryInterface {
    return new utils.Interface(_abi) as EtherspotWallet7579FactoryInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): EtherspotWallet7579Factory {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as EtherspotWallet7579Factory;
  }
}
