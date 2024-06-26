/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../../common";
import type {
  MockExecutor,
  MockExecutorInterface,
} from "../../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockExecutor";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "smartAccount",
        type: "address",
      },
    ],
    name: "AlreadyInitialized",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "smartAccount",
        type: "address",
      },
    ],
    name: "NotInitialized",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "contract IERC7579Account",
        name: "account",
        type: "address",
      },
      {
        components: [
          {
            internalType: "address",
            name: "target",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "value",
            type: "uint256",
          },
          {
            internalType: "bytes",
            name: "callData",
            type: "bytes",
          },
        ],
        internalType: "struct Execution[]",
        name: "execs",
        type: "tuple[]",
      },
    ],
    name: "execBatch",
    outputs: [
      {
        internalType: "bytes[]",
        name: "returnData",
        type: "bytes[]",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "contract IERC7579Account",
        name: "account",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "callData",
        type: "bytes",
      },
    ],
    name: "execDelegatecall",
    outputs: [
      {
        internalType: "bytes[]",
        name: "returnData",
        type: "bytes[]",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "contract IERC7579Account",
        name: "account",
        type: "address",
      },
      {
        internalType: "address",
        name: "target",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "callData",
        type: "bytes",
      },
    ],
    name: "executeViaAccount",
    outputs: [
      {
        internalType: "bytes[]",
        name: "returnData",
        type: "bytes[]",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "smartAccount",
        type: "address",
      },
    ],
    name: "isInitialized",
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
        internalType: "uint256",
        name: "moduleTypeId",
        type: "uint256",
      },
    ],
    name: "isModuleType",
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
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "onInstall",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "onUninstall",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b50610ab6806100206000396000f3fe608060405234801561001057600080fd5b506004361061007d5760003560e01c80636d61fe701161005b5780636d61fe70146100d15780638a91b0e3146100d1578063d60b347f146100e5578063ecd059611461010957600080fd5b80633006a107146100825780635873f200146100ab57806359053a55146100be575b600080fd5b61009561009036600461040b565b61011d565b6040516100a291906104ce565b60405180910390f35b6100956100b9366004610532565b6101e5565b6100956100cc366004610587565b61027a565b6100e36100df36600461060f565b5050565b005b6100f96100f3366004610651565b50600090565b60405190151581526020016100a2565b6100f9610117366004610675565b60021490565b6060856001600160a01b031663d691c9646101366102c2565b610177888888888080601f0160208091040260200160405190810160405280939291908181526020018383808284376000920191909152506102d592505050565b6040518363ffffffff1660e01b815260040161019492919061068e565b6000604051808303816000875af11580156101b3573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526101db9190810190610763565b9695505050505050565b60606001600160a01b03841663d691c96461020b6001600160f81b031960008080610304565b85856040518463ffffffff1660e01b815260040161022b93929190610855565b6000604051808303816000875af115801561024a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526102729190810190610763565b949350505050565b6060836001600160a01b031663d691c96461029361036f565b6102a56102a0868861088b565b610381565b6040518363ffffffff1660e01b815260040161022b92919061068e565b60006102d081808080610304565b905090565b60608383836040516020016102ec93929190610990565b60405160208183030381529060405290509392505050565b604080516001600160f81b03198087166020830152851660218201526000602282018190526001600160e01b03198516602683015269ffffffffffffffffffff198416602a8301529101604051602081830303815290604052610366906109cf565b95945050505050565b60006102d0600160f81b828080610304565b60608160405160200161039491906109f6565b6040516020818303038152906040529050919050565b6001600160a01b03811681146103bf57600080fd5b50565b60008083601f8401126103d457600080fd5b50813567ffffffffffffffff8111156103ec57600080fd5b60208301915083602082850101111561040457600080fd5b9250929050565b60008060008060006080868803121561042357600080fd5b853561042e816103aa565b9450602086013561043e816103aa565b935060408601359250606086013567ffffffffffffffff81111561046157600080fd5b61046d888289016103c2565b969995985093965092949392505050565b60005b83811015610499578181015183820152602001610481565b50506000910152565b600081518084526104ba81602086016020860161047e565b601f01601f19169290920160200192915050565b600060208083016020845280855180835260408601915060408160051b87010192506020870160005b8281101561052557603f198886030184526105138583516104a2565b945092850192908501906001016104f7565b5092979650505050505050565b60008060006040848603121561054757600080fd5b8335610552816103aa565b9250602084013567ffffffffffffffff81111561056e57600080fd5b61057a868287016103c2565b9497909650939450505050565b60008060006040848603121561059c57600080fd5b83356105a7816103aa565b9250602084013567ffffffffffffffff808211156105c457600080fd5b818601915086601f8301126105d857600080fd5b8135818111156105e757600080fd5b8760208260051b85010111156105fc57600080fd5b6020830194508093505050509250925092565b6000806020838503121561062257600080fd5b823567ffffffffffffffff81111561063957600080fd5b610645858286016103c2565b90969095509350505050565b60006020828403121561066357600080fd5b813561066e816103aa565b9392505050565b60006020828403121561068757600080fd5b5035919050565b82815260406020820152600061027260408301846104a2565b634e487b7160e01b600052604160045260246000fd5b6040516060810167ffffffffffffffff811182821017156106e0576106e06106a7565b60405290565b604051601f8201601f1916810167ffffffffffffffff8111828210171561070f5761070f6106a7565b604052919050565b600067ffffffffffffffff821115610731576107316106a7565b5060051b60200190565b600067ffffffffffffffff821115610755576107556106a7565b50601f01601f191660200190565b6000602080838503121561077657600080fd5b825167ffffffffffffffff8082111561078e57600080fd5b818501915085601f8301126107a257600080fd5b81516107b56107b082610717565b6106e6565b81815260059190911b830184019084810190888311156107d457600080fd5b8585015b83811015610848578051858111156107f05760008081fd5b8601603f81018b136108025760008081fd5b8781015160406108146107b08361073b565b8281528d828486010111156108295760008081fd5b610838838c830184870161047e565b86525050509186019186016107d8565b5098975050505050505050565b83815260406020820152816040820152818360608301376000818301606090810191909152601f909201601f1916010192915050565b60006108996107b084610717565b80848252602080830192508560051b8501368111156108b757600080fd5b855b8181101561098457803567ffffffffffffffff808211156108da5760008081fd5b8189019150606082360312156108f05760008081fd5b6108f86106bd565b8235610903816103aa565b81528286013586820152604080840135838111156109215760008081fd5b939093019236601f85011261093857600092508283fd5b833592506109486107b08461073b565b838152368885870101111561095d5760008081fd5b838886018983013760009381018801939093528101919091528652509382019382016108b9565b50919695505050505050565b6bffffffffffffffffffffffff198460601b168152826014820152600082516109c081603485016020870161047e565b91909101603401949350505050565b805160208083015191908110156109f0576000198160200360031b1b821691505b50919050565b600060208083018184528085518083526040925060408601915060408160051b87010184880160005b83811015610a7257888303603f19018552815180516001600160a01b0316845287810151888501528601516060878501819052610a5e818601836104a2565b968901969450505090860190600101610a1f565b50909897505050505050505056fea2646970667358221220909e52ad02bca4c6c9cdfb44010251d12d8a73bb32d289d10c7124b92c1b0fe164736f6c63430008170033";

type MockExecutorConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: MockExecutorConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class MockExecutor__factory extends ContractFactory {
  constructor(...args: MockExecutorConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<MockExecutor> {
    return super.deploy(overrides || {}) as Promise<MockExecutor>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): MockExecutor {
    return super.attach(address) as MockExecutor;
  }
  override connect(signer: Signer): MockExecutor__factory {
    return super.connect(signer) as MockExecutor__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MockExecutorInterface {
    return new utils.Interface(_abi) as MockExecutorInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MockExecutor {
    return new Contract(address, _abi, signerOrProvider) as MockExecutor;
  }
}
