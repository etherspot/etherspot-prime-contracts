/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../common";
import type {
  TestERC721,
  TestERC721Interface,
} from "../../../../src/modular-etherspot-wallet/test/TestERC721";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "sender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "ERC721IncorrectOwner",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "ERC721InsufficientApproval",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "approver",
        type: "address",
      },
    ],
    name: "ERC721InvalidApprover",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
    ],
    name: "ERC721InvalidOperator",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "ERC721InvalidOwner",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "receiver",
        type: "address",
      },
    ],
    name: "ERC721InvalidReceiver",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "sender",
        type: "address",
      },
    ],
    name: "ERC721InvalidSender",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "ERC721NonexistentToken",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "approved",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        indexed: false,
        internalType: "bool",
        name: "approved",
        type: "bool",
      },
    ],
    name: "ApprovalForAll",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "balanceOf",
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
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "getApproved",
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
        name: "owner",
        type: "address",
      },
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
    ],
    name: "isApprovedForAll",
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
        internalType: "address",
        name: "_to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_id",
        type: "uint256",
      },
    ],
    name: "mint",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "ownerOf",
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
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "safeTransferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "safeTransferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        internalType: "bool",
        name: "approved",
        type: "bool",
      },
    ],
    name: "setApprovalForAll",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
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
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "tokenURI",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60806040523480156200001157600080fd5b506040518060400160405280600a8152602001695465737445524337323160b01b81525060405180604001604052806004815260200163151154d560e21b815250816000908162000063919062000122565b50600162000072828262000122565b505050620001ee565b634e487b7160e01b600052604160045260246000fd5b600181811c90821680620000a657607f821691505b602082108103620000c757634e487b7160e01b600052602260045260246000fd5b50919050565b601f8211156200011d576000816000526020600020601f850160051c81016020861015620000f85750805b601f850160051c820191505b81811015620001195782815560010162000104565b5050505b505050565b81516001600160401b038111156200013e576200013e6200007b565b62000156816200014f845462000091565b84620000cd565b602080601f8311600181146200018e5760008415620001755750858301515b600019600386901b1c1916600185901b17855562000119565b600085815260208120601f198616915b82811015620001bf578886015182559484019460019091019084016200019e565b5085821015620001de5787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b610f7a80620001fe6000396000f3fe608060405234801561001057600080fd5b50600436106100ea5760003560e01c80636352211e1161008c578063a22cb46511610066578063a22cb465146101e1578063b88d4fde146101f4578063c87b56dd14610207578063e985e9c51461021a57600080fd5b80636352211e146101a557806370a08231146101b857806395d89b41146101d957600080fd5b8063095ea7b3116100c8578063095ea7b31461015757806323b872dd1461016c57806340c10f191461017f57806342842e0e1461019257600080fd5b806301ffc9a7146100ef57806306fdde0314610117578063081812fc1461012c575b600080fd5b6101026100fd366004610bea565b61022d565b60405190151581526020015b60405180910390f35b61011f61027f565b60405161010e9190610c57565b61013f61013a366004610c6a565b610311565b6040516001600160a01b03909116815260200161010e565b61016a610165366004610c9f565b61033a565b005b61016a61017a366004610cc9565b610349565b61016a61018d366004610c9f565b6103d9565b61016a6101a0366004610cc9565b6103e3565b61013f6101b3366004610c6a565b610403565b6101cb6101c6366004610d05565b61040e565b60405190815260200161010e565b61011f610456565b61016a6101ef366004610d20565b610465565b61016a610202366004610d72565b610470565b61011f610215366004610c6a565b610487565b610102610228366004610e4e565b6104fc565b60006001600160e01b031982166380ac58cd60e01b148061025e57506001600160e01b03198216635b5e139f60e01b145b8061027957506301ffc9a760e01b6001600160e01b03198316145b92915050565b60606000805461028e90610e81565b80601f01602080910402602001604051908101604052809291908181526020018280546102ba90610e81565b80156103075780601f106102dc57610100808354040283529160200191610307565b820191906000526020600020905b8154815290600101906020018083116102ea57829003601f168201915b5050505050905090565b600061031c8261052a565b506000828152600460205260409020546001600160a01b0316610279565b610345828233610563565b5050565b6001600160a01b03821661037857604051633250574960e11b8152600060048201526024015b60405180910390fd5b6000610385838333610570565b9050836001600160a01b0316816001600160a01b0316146103d3576040516364283d7b60e01b81526001600160a01b038086166004830152602482018490528216604482015260640161036f565b50505050565b6103458282610669565b6103fe83838360405180602001604052806000815250610470565b505050565b60006102798261052a565b60006001600160a01b03821661043a576040516322718ad960e21b81526000600482015260240161036f565b506001600160a01b031660009081526003602052604090205490565b60606001805461028e90610e81565b6103453383836106ce565b61047b848484610349565b6103d38484848461076d565b60606104928261052a565b5060006104aa60408051602081019091526000815290565b905060008151116104ca57604051806020016040528060008152506104f5565b806104d484610896565b6040516020016104e5929190610ebb565b6040516020818303038152906040525b9392505050565b6001600160a01b03918216600090815260056020908152604080832093909416825291909152205460ff1690565b6000818152600260205260408120546001600160a01b03168061027957604051637e27328960e01b81526004810184905260240161036f565b6103fe8383836001610929565b6000828152600260205260408120546001600160a01b039081169083161561059d5761059d818486610a2f565b6001600160a01b038116156105db576105ba600085600080610929565b6001600160a01b038116600090815260036020526040902080546000190190555b6001600160a01b0385161561060a576001600160a01b0385166000908152600360205260409020805460010190555b60008481526002602052604080822080546001600160a01b0319166001600160a01b0389811691821790925591518793918516917fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef91a4949350505050565b6001600160a01b03821661069357604051633250574960e11b81526000600482015260240161036f565b60006106a183836000610570565b90506001600160a01b038116156103fe576040516339e3563760e11b81526000600482015260240161036f565b6001600160a01b03821661070057604051630b61174360e31b81526001600160a01b038316600482015260240161036f565b6001600160a01b03838116600081815260056020908152604080832094871680845294825291829020805460ff191686151590811790915591519182527f17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31910160405180910390a3505050565b6001600160a01b0383163b156103d357604051630a85bd0160e11b81526001600160a01b0384169063150b7a02906107af903390889087908790600401610eea565b6020604051808303816000875af19250505080156107ea575060408051601f3d908101601f191682019092526107e791810190610f27565b60015b610853573d808015610818576040519150601f19603f3d011682016040523d82523d6000602084013e61081d565b606091505b50805160000361084b57604051633250574960e11b81526001600160a01b038516600482015260240161036f565b805181602001fd5b6001600160e01b03198116630a85bd0160e11b1461088f57604051633250574960e11b81526001600160a01b038516600482015260240161036f565b5050505050565b606060006108a383610a93565b600101905060008167ffffffffffffffff8111156108c3576108c3610d5c565b6040519080825280601f01601f1916602001820160405280156108ed576020820181803683370190505b5090508181016020015b600019016f181899199a1a9b1b9c1cb0b131b232b360811b600a86061a8153600a85049450846108f757509392505050565b808061093d57506001600160a01b03821615155b156109ff57600061094d8461052a565b90506001600160a01b038316158015906109795750826001600160a01b0316816001600160a01b031614155b801561098c575061098a81846104fc565b155b156109b55760405163a9fbf51f60e01b81526001600160a01b038416600482015260240161036f565b81156109fd5783856001600160a01b0316826001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92560405160405180910390a45b505b5050600090815260046020526040902080546001600160a01b0319166001600160a01b0392909216919091179055565b610a3a838383610b6b565b6103fe576001600160a01b038316610a6857604051637e27328960e01b81526004810182905260240161036f565b60405163177e802f60e01b81526001600160a01b03831660048201526024810182905260440161036f565b60008072184f03e93ff9f4daa797ed6e38ed64bf6a1f0160401b8310610ad25772184f03e93ff9f4daa797ed6e38ed64bf6a1f0160401b830492506040015b6d04ee2d6d415b85acef81000000008310610afe576d04ee2d6d415b85acef8100000000830492506020015b662386f26fc100008310610b1c57662386f26fc10000830492506010015b6305f5e1008310610b34576305f5e100830492506008015b6127108310610b4857612710830492506004015b60648310610b5a576064830492506002015b600a83106102795760010192915050565b60006001600160a01b03831615801590610bc95750826001600160a01b0316846001600160a01b03161480610ba55750610ba584846104fc565b80610bc957506000828152600460205260409020546001600160a01b038481169116145b949350505050565b6001600160e01b031981168114610be757600080fd5b50565b600060208284031215610bfc57600080fd5b81356104f581610bd1565b60005b83811015610c22578181015183820152602001610c0a565b50506000910152565b60008151808452610c43816020860160208601610c07565b601f01601f19169290920160200192915050565b6020815260006104f56020830184610c2b565b600060208284031215610c7c57600080fd5b5035919050565b80356001600160a01b0381168114610c9a57600080fd5b919050565b60008060408385031215610cb257600080fd5b610cbb83610c83565b946020939093013593505050565b600080600060608486031215610cde57600080fd5b610ce784610c83565b9250610cf560208501610c83565b9150604084013590509250925092565b600060208284031215610d1757600080fd5b6104f582610c83565b60008060408385031215610d3357600080fd5b610d3c83610c83565b915060208301358015158114610d5157600080fd5b809150509250929050565b634e487b7160e01b600052604160045260246000fd5b60008060008060808587031215610d8857600080fd5b610d9185610c83565b9350610d9f60208601610c83565b925060408501359150606085013567ffffffffffffffff80821115610dc357600080fd5b818701915087601f830112610dd757600080fd5b813581811115610de957610de9610d5c565b604051601f8201601f19908116603f01168101908382118183101715610e1157610e11610d5c565b816040528281528a6020848701011115610e2a57600080fd5b82602086016020830137600060208483010152809550505050505092959194509250565b60008060408385031215610e6157600080fd5b610e6a83610c83565b9150610e7860208401610c83565b90509250929050565b600181811c90821680610e9557607f821691505b602082108103610eb557634e487b7160e01b600052602260045260246000fd5b50919050565b60008351610ecd818460208801610c07565b835190830190610ee1818360208801610c07565b01949350505050565b6001600160a01b0385811682528416602082015260408101839052608060608201819052600090610f1d90830184610c2b565b9695505050505050565b600060208284031215610f3957600080fd5b81516104f581610bd156fea264697066735822122008fb3bb053b0c1c8d6791fe09d6aa24389c72849d87af0d39f11b6e5da5a71ca64736f6c63430008170033";

type TestERC721ConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: TestERC721ConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class TestERC721__factory extends ContractFactory {
  constructor(...args: TestERC721ConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<TestERC721> {
    return super.deploy(overrides || {}) as Promise<TestERC721>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): TestERC721 {
    return super.attach(address) as TestERC721;
  }
  override connect(signer: Signer): TestERC721__factory {
    return super.connect(signer) as TestERC721__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): TestERC721Interface {
    return new utils.Interface(_abi) as TestERC721Interface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): TestERC721 {
    return new Contract(address, _abi, signerOrProvider) as TestERC721;
  }
}
