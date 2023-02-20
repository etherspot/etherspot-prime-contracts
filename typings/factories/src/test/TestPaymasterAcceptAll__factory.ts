/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  TestPaymasterAcceptAll,
  TestPaymasterAcceptAllInterface,
} from "../../../src/test/TestPaymasterAcceptAll";

const _abi = [
  {
    inputs: [
      {
        internalType: "contract IEntryPoint",
        name: "_entryPoint",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
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
    inputs: [
      {
        internalType: "uint32",
        name: "unstakeDelaySec",
        type: "uint32",
      },
    ],
    name: "addStake",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "deposit",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "entryPoint",
    outputs: [
      {
        internalType: "contract IEntryPoint",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getDeposit",
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
        internalType: "enum IPaymaster.PostOpMode",
        name: "mode",
        type: "uint8",
      },
      {
        internalType: "bytes",
        name: "context",
        type: "bytes",
      },
      {
        internalType: "uint256",
        name: "actualGasCost",
        type: "uint256",
      },
    ],
    name: "postOp",
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
        internalType: "contract IEntryPoint",
        name: "_entryPoint",
        type: "address",
      },
    ],
    name: "setEntryPoint",
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
    inputs: [],
    name: "unlockStake",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          {
            internalType: "address",
            name: "sender",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "nonce",
            type: "uint256",
          },
          {
            internalType: "bytes",
            name: "initCode",
            type: "bytes",
          },
          {
            internalType: "bytes",
            name: "callData",
            type: "bytes",
          },
          {
            internalType: "uint256",
            name: "callGasLimit",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "verificationGasLimit",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "preVerificationGas",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "maxFeePerGas",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "maxPriorityFeePerGas",
            type: "uint256",
          },
          {
            internalType: "bytes",
            name: "paymasterAndData",
            type: "bytes",
          },
          {
            internalType: "bytes",
            name: "signature",
            type: "bytes",
          },
        ],
        internalType: "struct UserOperation",
        name: "userOp",
        type: "tuple",
      },
      {
        internalType: "bytes32",
        name: "userOpHash",
        type: "bytes32",
      },
      {
        internalType: "uint256",
        name: "maxCost",
        type: "uint256",
      },
    ],
    name: "validatePaymasterUserOp",
    outputs: [
      {
        internalType: "bytes",
        name: "context",
        type: "bytes",
      },
      {
        internalType: "uint256",
        name: "deadline",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address payable",
        name: "withdrawAddress",
        type: "address",
      },
    ],
    name: "withdrawStake",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address payable",
        name: "withdrawAddress",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "withdrawTo",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60806040523480156200001157600080fd5b506040516200156f3803806200156f83398181016040528101906200003791906200030f565b80620000586200004c620000b760201b60201c565b620000bf60201b60201c565b62000069816200018360201b60201c565b503373ffffffffffffffffffffffffffffffffffffffff163273ffffffffffffffffffffffffffffffffffffffff1614620000b057620000af32620000bf60201b60201c565b5b50620003c4565b600033905090565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050816000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508173ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a35050565b62000193620001d760201b60201c565b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b620001e7620000b760201b60201c565b73ffffffffffffffffffffffffffffffffffffffff166200020d6200026860201b60201c565b73ffffffffffffffffffffffffffffffffffffffff161462000266576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016200025d90620003a2565b60405180910390fd5b565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000620002c38262000296565b9050919050565b6000620002d782620002b6565b9050919050565b620002e981620002ca565b8114620002f557600080fd5b50565b6000815190506200030981620002de565b92915050565b60006020828403121562000328576200032762000291565b5b60006200033884828501620002f8565b91505092915050565b600082825260208201905092915050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b60006200038a60208362000341565b9150620003978262000352565b602082019050919050565b60006020820190508181036000830152620003bd816200037b565b9050919050565b61119b80620003d46000396000f3fe6080604052600436106100c25760003560e01c8063b0d691fe1161007f578063c399ec8811610059578063c399ec881461020b578063d0e30db014610236578063f2fde38b14610240578063f465c77e14610269576100c2565b8063b0d691fe146101a0578063bb9fe6bf146101cb578063c23a5cea146101e2576100c2565b80630396cb60146100c7578063205c2878146100e3578063584465f21461010c578063715018a6146101355780638da5cb5b1461014c578063a9a2340914610177575b600080fd5b6100e160048036038101906100dc91906109c8565b6102a7565b005b3480156100ef57600080fd5b5061010a60048036038101906101059190610a89565b610340565b005b34801561011857600080fd5b50610133600480360381019061012e9190610b19565b6103db565b005b34801561014157600080fd5b5061014a610427565b005b34801561015857600080fd5b5061016161043b565b60405161016e9190610b55565b60405180910390f35b34801561018357600080fd5b5061019e60048036038101906101999190610bfa565b610464565b005b3480156101ac57600080fd5b506101b561047e565b6040516101c29190610ccd565b60405180910390f35b3480156101d757600080fd5b506101e06104a4565b005b3480156101ee57600080fd5b5061020960048036038101906102049190610ce8565b610530565b005b34801561021757600080fd5b506102206105c8565b60405161022d9190610d24565b60405180910390f35b61023e61066b565b005b34801561024c57600080fd5b5061026760048036038101906102629190610d6b565b6106fb565b005b34801561027557600080fd5b50610290600480360381019061028b9190610df3565b61077f565b60405161029e929190610efb565b60405180910390f35b6102af6107a1565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16630396cb6034836040518363ffffffff1660e01b815260040161030b9190610f3a565b6000604051808303818588803b15801561032457600080fd5b505af1158015610338573d6000803e3d6000fd5b505050505050565b6103486107a1565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663205c287883836040518363ffffffff1660e01b81526004016103a5929190610f64565b600060405180830381600087803b1580156103bf57600080fd5b505af11580156103d3573d6000803e3d6000fd5b505050505050565b6103e36107a1565b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b61042f6107a1565b610439600061081f565b565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b61046c6108e3565b6104788484848461093f565b50505050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6104ac6107a1565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663bb9fe6bf6040518163ffffffff1660e01b8152600401600060405180830381600087803b15801561051657600080fd5b505af115801561052a573d6000803e3d6000fd5b50505050565b6105386107a1565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663c23a5cea826040518263ffffffff1660e01b81526004016105939190610f8d565b600060405180830381600087803b1580156105ad57600080fd5b505af11580156105c1573d6000803e3d6000fd5b5050505050565b6000600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166370a08231306040518263ffffffff1660e01b81526004016106259190610b55565b602060405180830381865afa158015610642573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906106669190610fbd565b905090565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663b760faf934306040518363ffffffff1660e01b81526004016106c79190610b55565b6000604051808303818588803b1580156106e057600080fd5b505af11580156106f4573d6000803e3d6000fd5b5050505050565b6107036107a1565b600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff161415610773576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161076a9061106d565b60405180910390fd5b61077c8161081f565b50565b6060600080604051806020016040528060008152509091509150935093915050565b6107a961097a565b73ffffffffffffffffffffffffffffffffffffffff166107c761043b565b73ffffffffffffffffffffffffffffffffffffffff161461081d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610814906110d9565b60405180910390fd5b565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050816000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508173ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a35050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461093d57600080fd5b565b6040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161097190611145565b60405180910390fd5b600033905090565b600080fd5b600080fd5b600063ffffffff82169050919050565b6109a58161098c565b81146109b057600080fd5b50565b6000813590506109c28161099c565b92915050565b6000602082840312156109de576109dd610982565b5b60006109ec848285016109b3565b91505092915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610a20826109f5565b9050919050565b610a3081610a15565b8114610a3b57600080fd5b50565b600081359050610a4d81610a27565b92915050565b6000819050919050565b610a6681610a53565b8114610a7157600080fd5b50565b600081359050610a8381610a5d565b92915050565b60008060408385031215610aa057610a9f610982565b5b6000610aae85828601610a3e565b9250506020610abf85828601610a74565b9150509250929050565b6000610ad4826109f5565b9050919050565b6000610ae682610ac9565b9050919050565b610af681610adb565b8114610b0157600080fd5b50565b600081359050610b1381610aed565b92915050565b600060208284031215610b2f57610b2e610982565b5b6000610b3d84828501610b04565b91505092915050565b610b4f81610ac9565b82525050565b6000602082019050610b6a6000830184610b46565b92915050565b60038110610b7d57600080fd5b50565b600081359050610b8f81610b70565b92915050565b600080fd5b600080fd5b600080fd5b60008083601f840112610bba57610bb9610b95565b5b8235905067ffffffffffffffff811115610bd757610bd6610b9a565b5b602083019150836001820283011115610bf357610bf2610b9f565b5b9250929050565b60008060008060608587031215610c1457610c13610982565b5b6000610c2287828801610b80565b945050602085013567ffffffffffffffff811115610c4357610c42610987565b5b610c4f87828801610ba4565b93509350506040610c6287828801610a74565b91505092959194509250565b6000819050919050565b6000610c93610c8e610c89846109f5565b610c6e565b6109f5565b9050919050565b6000610ca582610c78565b9050919050565b6000610cb782610c9a565b9050919050565b610cc781610cac565b82525050565b6000602082019050610ce26000830184610cbe565b92915050565b600060208284031215610cfe57610cfd610982565b5b6000610d0c84828501610a3e565b91505092915050565b610d1e81610a53565b82525050565b6000602082019050610d396000830184610d15565b92915050565b610d4881610ac9565b8114610d5357600080fd5b50565b600081359050610d6581610d3f565b92915050565b600060208284031215610d8157610d80610982565b5b6000610d8f84828501610d56565b91505092915050565b600080fd5b60006101608284031215610db457610db3610d98565b5b81905092915050565b6000819050919050565b610dd081610dbd565b8114610ddb57600080fd5b50565b600081359050610ded81610dc7565b92915050565b600080600060608486031215610e0c57610e0b610982565b5b600084013567ffffffffffffffff811115610e2a57610e29610987565b5b610e3686828701610d9d565b9350506020610e4786828701610dde565b9250506040610e5886828701610a74565b9150509250925092565b600081519050919050565b600082825260208201905092915050565b60005b83811015610e9c578082015181840152602081019050610e81565b83811115610eab576000848401525b50505050565b6000601f19601f8301169050919050565b6000610ecd82610e62565b610ed78185610e6d565b9350610ee7818560208601610e7e565b610ef081610eb1565b840191505092915050565b60006040820190508181036000830152610f158185610ec2565b9050610f246020830184610d15565b9392505050565b610f348161098c565b82525050565b6000602082019050610f4f6000830184610f2b565b92915050565b610f5e81610a15565b82525050565b6000604082019050610f796000830185610f55565b610f866020830184610d15565b9392505050565b6000602082019050610fa26000830184610f55565b92915050565b600081519050610fb781610a5d565b92915050565b600060208284031215610fd357610fd2610982565b5b6000610fe184828501610fa8565b91505092915050565b600082825260208201905092915050565b7f4f776e61626c653a206e6577206f776e657220697320746865207a65726f206160008201527f6464726573730000000000000000000000000000000000000000000000000000602082015250565b6000611057602683610fea565b915061106282610ffb565b604082019050919050565b600060208201905081810360008301526110868161104a565b9050919050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b60006110c3602083610fea565b91506110ce8261108d565b602082019050919050565b600060208201905081810360008301526110f2816110b6565b9050919050565b7f6d757374206f7665727269646500000000000000000000000000000000000000600082015250565b600061112f600d83610fea565b915061113a826110f9565b602082019050919050565b6000602082019050818103600083015261115e81611122565b905091905056fea264697066735822122016fc66f1a5a51a9afd282e92e33261c3e122812cb34eb886fb6732cbf44324bb64736f6c634300080c0033";

type TestPaymasterAcceptAllConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: TestPaymasterAcceptAllConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class TestPaymasterAcceptAll__factory extends ContractFactory {
  constructor(...args: TestPaymasterAcceptAllConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    _entryPoint: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<TestPaymasterAcceptAll> {
    return super.deploy(
      _entryPoint,
      overrides || {}
    ) as Promise<TestPaymasterAcceptAll>;
  }
  override getDeployTransaction(
    _entryPoint: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(_entryPoint, overrides || {});
  }
  override attach(address: string): TestPaymasterAcceptAll {
    return super.attach(address) as TestPaymasterAcceptAll;
  }
  override connect(signer: Signer): TestPaymasterAcceptAll__factory {
    return super.connect(signer) as TestPaymasterAcceptAll__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): TestPaymasterAcceptAllInterface {
    return new utils.Interface(_abi) as TestPaymasterAcceptAllInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): TestPaymasterAcceptAll {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as TestPaymasterAcceptAll;
  }
}
