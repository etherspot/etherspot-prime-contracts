/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  Whitelist,
  WhitelistInterface,
} from "../../../src/paymaster/Whitelist";

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
        name: "previousOwner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
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
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "WhitelistInitialized",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
    ],
    name: "add",
    outputs: [],
    stateMutability: "nonpayable",
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
    name: "addBatch",
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
    inputs: [],
    name: "owner",
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
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
    ],
    name: "remove",
    outputs: [],
    stateMutability: "nonpayable",
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
    name: "removeBatch",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "renounceOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "whitelist",
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
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b5061001a3361001f565b61006f565b600080546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b6108108061007e6000396000f3fe608060405234801561001057600080fd5b50600436106100935760003560e01c8063715018a611610066578063715018a6146100e65780638da5cb5b146100ee578063b092145e1461010e578063b3154db01461014c578063f2fde38b1461015f57600080fd5b80630a3b0a4f1461009857806324efa264146100ad57806329092d0e146100c05780636b845bfe146100d3575b600080fd5b6100ab6100a636600461069a565b610172565b005b6100ab6100bb3660046106b5565b6101b4565b6100ab6100ce36600461069a565b610204565b6100ab6100e13660046106b5565b610246565b6100ab610296565b6000546040516001600160a01b0390911681526020015b60405180910390f35b61013c61011c36600461072a565b600160209081526000928352604080842090915290825290205460ff1681565b6040519015158152602001610105565b61013c61015a36600461072a565b6102aa565b6100ab61016d36600461069a565b6102bd565b61017b8161033b565b6040516001600160a01b0382169033907f0c4b48e75a1f7ab0a9a2f786b5d6c1f7789020403bff177fb54d46edb89ccc0090600090a350565b6101be8282610429565b81816040516101ce92919061075d565b6040519081900381209033907f6eabb183ad4385932735ae89018089a008c58e814451b618bc0dd0e7922f6d1390600090a35050565b61020d81610478565b6040516001600160a01b0382169033907fd288ab5da2e1f37cf384a1565a3f905ad289b092fbdd31950dbbfef148c04f8890600090a350565b610250828261055c565b818160405161026092919061075d565b6040519081900381209033907f75dcdde27b71b9c529ae8b02072e1eeda244662d2d9c2effea5a1afb8fc913f390600090a35050565b61029e6105a6565b6102a86000610600565b565b60006102b68383610650565b9392505050565b6102c56105a6565b6001600160a01b03811661032f5760405162461bcd60e51b815260206004820152602660248201527f4f776e61626c653a206e6577206f776e657220697320746865207a65726f206160448201526564647265737360d01b60648201526084015b60405180910390fd5b61033881610600565b50565b6001600160a01b03811661038c5760405162461bcd60e51b815260206004820152601860248201527757686974656c6973743a3a205a65726f206164647265737360401b6044820152606401610326565b6103963382610650565b156103f65760405162461bcd60e51b815260206004820152602a60248201527f57686974656c6973743a3a204163636f756e7420697320616c726561647920776044820152691a1a5d195b1a5cdd195960b21b6064820152608401610326565b3360009081526001602081815260408084206001600160a01b03959095168452939052919020805460ff19169091179055565b60005b81811015610473576104638383838181106104495761044961079d565b905060200201602081019061045e919061069a565b61033b565b61046c816107b3565b905061042c565b505050565b6001600160a01b0381166104c95760405162461bcd60e51b815260206004820152601860248201527757686974656c6973743a3a205a65726f206164647265737360401b6044820152606401610326565b6104d33382610650565b61052e5760405162461bcd60e51b815260206004820152602660248201527f57686974656c6973743a3a204163636f756e74206973206e6f742077686974656044820152651b1a5cdd195960d21b6064820152608401610326565b3360009081526001602090815260408083206001600160a01b0394909416835292905220805460ff19169055565b60005b818110156104735761059683838381811061057c5761057c61079d565b9050602002016020810190610591919061069a565b610478565b61059f816107b3565b905061055f565b6000546001600160a01b031633146102a85760405162461bcd60e51b815260206004820181905260248201527f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e65726044820152606401610326565b600080546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b6001600160a01b03918216600090815260016020908152604080832093909416825291909152205460ff1690565b80356001600160a01b038116811461069557600080fd5b919050565b6000602082840312156106ac57600080fd5b6102b68261067e565b600080602083850312156106c857600080fd5b823567ffffffffffffffff808211156106e057600080fd5b818501915085601f8301126106f457600080fd5b81358181111561070357600080fd5b8660208260051b850101111561071857600080fd5b60209290920196919550909350505050565b6000806040838503121561073d57600080fd5b6107468361067e565b91506107546020840161067e565b90509250929050565b60008184825b85811015610792576001600160a01b0361077c8361067e565b1683526020928301929190910190600101610763565b509095945050505050565b634e487b7160e01b600052603260045260246000fd5b6000600182016107d357634e487b7160e01b600052601160045260246000fd5b506001019056fea26469706673582212206106b6b58f6215662e17a88ed1ec5cb4fee961ed510b9188325ad808f7cf46c864736f6c63430008110033";

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
