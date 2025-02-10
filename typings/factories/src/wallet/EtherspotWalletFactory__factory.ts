/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  EtherspotWalletFactory,
  EtherspotWalletFactoryInterface,
} from "../../../src/wallet/EtherspotWalletFactory";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_owner",
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
        name: "wallet",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "index",
        type: "uint256",
      },
    ],
    name: "AccountCreation",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "newImplementation",
        type: "address",
      },
    ],
    name: "ImplementationSet",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnerChanged",
    type: "event",
  },
  {
    inputs: [],
    name: "accountCreationCode",
    outputs: [
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [],
    name: "accountImplementation",
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
        name: "_newOwner",
        type: "address",
      },
    ],
    name: "changeOwner",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_impl",
        type: "address",
      },
    ],
    name: "checkImplementation",
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
        name: "_owner",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_index",
        type: "uint256",
      },
    ],
    name: "createAccount",
    outputs: [
      {
        internalType: "address",
        name: "ret",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_owner",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_index",
        type: "uint256",
      },
    ],
    name: "getAddress",
    outputs: [
      {
        internalType: "address",
        name: "proxy",
        type: "address",
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
        internalType: "contract EtherspotWallet",
        name: "_newImpl",
        type: "address",
      },
    ],
    name: "setImplementation",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b506040516109eb3803806109eb83398101604081905261002f91610054565b600180546001600160a01b0319166001600160a01b0392909216919091179055610084565b60006020828403121561006657600080fd5b81516001600160a01b038116811461007d57600080fd5b9392505050565b610958806100936000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c80638da5cb5b1161005b5780638da5cb5b146100f8578063a6f9dae11461010b578063d784d42614610120578063e6c0c5971461013357600080fd5b806311464fbe1461008d57806331c884df146100bd5780635fbfb9cf146100d25780638cb84e18146100e5575b600080fd5b6000546100a0906001600160a01b031681565b6040516001600160a01b0390911681526020015b60405180910390f35b6100c5610165565b6040516100b49190610667565b6100a06100e03660046106b2565b61018f565b6100a06100f33660046106b2565b610355565b6001546100a0906001600160a01b031681565b61011e6101193660046106de565b61047b565b005b61011e61012e3660046106de565b610576565b6101556101413660046106de565b6000546001600160a01b0390811691161490565b60405190151581526020016100b4565b60606040518060200161017790610636565b601f1982820381018352601f90910116604052919050565b600080546001600160a01b03166101c15760405162461bcd60e51b81526004016101b890610702565b60405180910390fd5b60006101cd8484610355565b90506001600160a01b0381163b156101e657905061034f565b60006101f1856105ee565b90506000818051906020012085604051602001610218929190918252602082015260400190565b60405160208183030381529060405280519060200120905060006040518060200161024290610636565b601f1982820381018352601f90910116604081905260005461027392916001600160a01b0390911690602001610751565b6040516020818303038152906040529050818151826020016000f594506001600160a01b0385166102dc5760405162461bcd60e51b815260206004820152601360248201527210dc99585d194c8818d85b1b0819985a5b1959606a1b60448201526064016101b8565b8251156102fd57600080600085516020870160008a5af1036102fd57600080fd5b866001600160a01b0316856001600160a01b03167f8967dcaa00d8fcb9bb2b5beff4aaf8c020063512cf08fbe11fec37a1e3a150f28860405161034291815260200190565b60405180910390a3505050505b92915050565b600080546001600160a01b031661037e5760405162461bcd60e51b81526004016101b890610702565b6000610389846105ee565b905060008180519060200120846040516020016103b0929190918252602082015260400190565b6040516020818303038152906040528051906020012090506000604051806020016103da90610636565b601f1982820381018352601f90910116604081905260005461040b92916001600160a01b0390911690602001610751565b60408051808303601f1901815282825280516020918201206001600160f81b0319828501523060601b6bffffffffffffffffffffffff1916602185015260358401959095526055808401959095528151808403909501855260759092019052825192019190912095945050505050565b6001546001600160a01b031633146104a55760405162461bcd60e51b81526004016101b890610773565b6001600160a01b0381166105215760405162461bcd60e51b815260206004820152603960248201527f457468657273706f7457616c6c6574466163746f72793a3a206e6577206f776e60448201527f65722063616e6e6f74206265207a65726f20616464726573730000000000000060648201526084016101b8565b600180546001600160a01b0319166001600160a01b0383169081179091556040519081527fa2ea9883a321a3e97b8266c2b078bfeec6d50c711ed71f874a90d500ae2eaf36906020015b60405180910390a150565b6001546001600160a01b031633146105a05760405162461bcd60e51b81526004016101b890610773565b600080546001600160a01b0319166001600160a01b0383169081179091556040519081527fab64f92ab780ecbf4f3866f57cee465ff36c89450dcce20237ca7a8d81fb7d139060200161056b565b6040516001600160a01b038216602482015260609060440160408051601f198184030181529190526020810180516001600160e01b031663189acdbd60e31b17905292915050565b61016c806107b783390190565b60005b8381101561065e578181015183820152602001610646565b50506000910152565b6020815260008251806020840152610686816040850160208701610643565b601f01601f19169190910160400192915050565b6001600160a01b03811681146106af57600080fd5b50565b600080604083850312156106c557600080fd5b82356106d08161069a565b946020939093013593505050565b6000602082840312156106f057600080fd5b81356106fb8161069a565b9392505050565b6020808252602f908201527f457468657273706f7457616c6c6574466163746f72793a3a20696d706c656d6560408201526e1b9d185d1a5bdb881b9bdd081cd95d608a1b606082015260800190565b60008351610763818460208801610643565b9190910191825250602001919050565b60208082526023908201527f457468657273706f7457616c6c6574466163746f72793a3a206f6e6c79206f776040820152623732b960e91b60608201526080019056fe608060405234801561001057600080fd5b5060405161016c38038061016c83398101604081905261002f916100b0565b6001600160a01b0381166100895760405162461bcd60e51b815260206004820152601860248201527f496e76616c696420616464726573732070726f76696465640000000000000000604482015260640160405180910390fd5b7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc556100e0565b6000602082840312156100c257600080fd5b81516001600160a01b03811681146100d957600080fd5b9392505050565b607e806100ee6000396000f3fe60806040527f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc543660008037600080366000845af43d6000803e806042573d6000fd5b503d6000f3fea26469706673582212205c71a895cf1f4c8f6630c10cf9e05411128bb41babccf7f6c6fddc1f0f80391064736f6c63430008170033a2646970667358221220d326507dd6f5f370f64941ff356693dc0a646b859c9ec7b294e67c7286e75dd064736f6c63430008170033";

type EtherspotWalletFactoryConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: EtherspotWalletFactoryConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class EtherspotWalletFactory__factory extends ContractFactory {
  constructor(...args: EtherspotWalletFactoryConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    _owner: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<EtherspotWalletFactory> {
    return super.deploy(
      _owner,
      overrides || {}
    ) as Promise<EtherspotWalletFactory>;
  }
  override getDeployTransaction(
    _owner: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(_owner, overrides || {});
  }
  override attach(address: string): EtherspotWalletFactory {
    return super.attach(address) as EtherspotWalletFactory;
  }
  override connect(signer: Signer): EtherspotWalletFactory__factory {
    return super.connect(signer) as EtherspotWalletFactory__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): EtherspotWalletFactoryInterface {
    return new utils.Interface(_abi) as EtherspotWalletFactoryInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): EtherspotWalletFactory {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as EtherspotWalletFactory;
  }
}
