/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from 'ethers';
import type { Provider, TransactionRequest } from '@ethersproject/providers';
import type { PromiseOrValue } from '../../../../../common';
import type {
  MultipleOwnerECDSAValidator,
  MultipleOwnerECDSAValidatorInterface,
} from '../../../../../src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator';

const _abi = [
  {
    inputs: [
      {
        internalType: 'address',
        name: 'smartAccount',
        type: 'address',
      },
    ],
    name: 'AlreadyInitialized',
    type: 'error',
  },
  {
    inputs: [],
    name: 'InvalidExec',
    type: 'error',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'target',
        type: 'address',
      },
    ],
    name: 'InvalidTargetAddress',
    type: 'error',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'smartAccount',
        type: 'address',
      },
    ],
    name: 'NotInitialized',
    type: 'error',
  },
  {
    inputs: [],
    name: 'RequiredModule',
    type: 'error',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'smartAccount',
        type: 'address',
      },
    ],
    name: 'isInitialized',
    outputs: [
      {
        internalType: 'bool',
        name: '',
        type: 'bool',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'uint256',
        name: 'typeID',
        type: 'uint256',
      },
    ],
    name: 'isModuleType',
    outputs: [
      {
        internalType: 'bool',
        name: '',
        type: 'bool',
      },
    ],
    stateMutability: 'pure',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: '',
        type: 'address',
      },
      {
        internalType: 'bytes32',
        name: 'hash',
        type: 'bytes32',
      },
      {
        internalType: 'bytes',
        name: 'data',
        type: 'bytes',
      },
    ],
    name: 'isValidSignatureWithSender',
    outputs: [
      {
        internalType: 'bytes4',
        name: '',
        type: 'bytes4',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'bytes',
        name: 'data',
        type: 'bytes',
      },
    ],
    name: 'onInstall',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'bytes',
        name: 'data',
        type: 'bytes',
      },
    ],
    name: 'onUninstall',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      {
        components: [
          {
            internalType: 'address',
            name: 'sender',
            type: 'address',
          },
          {
            internalType: 'uint256',
            name: 'nonce',
            type: 'uint256',
          },
          {
            internalType: 'bytes',
            name: 'initCode',
            type: 'bytes',
          },
          {
            internalType: 'bytes',
            name: 'callData',
            type: 'bytes',
          },
          {
            internalType: 'bytes32',
            name: 'accountGasLimits',
            type: 'bytes32',
          },
          {
            internalType: 'uint256',
            name: 'preVerificationGas',
            type: 'uint256',
          },
          {
            internalType: 'bytes32',
            name: 'gasFees',
            type: 'bytes32',
          },
          {
            internalType: 'bytes',
            name: 'paymasterAndData',
            type: 'bytes',
          },
          {
            internalType: 'bytes',
            name: 'signature',
            type: 'bytes',
          },
        ],
        internalType: 'struct PackedUserOperation',
        name: 'userOp',
        type: 'tuple',
      },
      {
        internalType: 'bytes32',
        name: 'userOpHash',
        type: 'bytes32',
      },
    ],
    name: 'validateUserOp',
    outputs: [
      {
        internalType: 'uint256',
        name: '',
        type: 'uint256',
      },
    ],
    stateMutability: 'nonpayable',
    type: 'function',
  },
] as const;

const _bytecode =
  '0x608060405234801561001057600080fd5b50610dfa806100206000396000f3fe608060405234801561001057600080fd5b50600436106100625760003560e01c80636d61fe70146100675780638a91b0e314610083578063970032031461009f578063d60b347f146100cf578063ecd05961146100ff578063f551e2ee1461012f575b600080fd5b610081600480360381019061007c91906107de565b61015f565b005b61009d600480360381019061009891906107de565b610205565b005b6100b960048036038101906100b49190610886565b610237565b6040516100c691906108fb565b60405180910390f35b6100e960048036038101906100e49190610974565b610463565b6040516100f691906109bc565b60405180910390f35b61011960048036038101906101149190610a03565b6104b8565b60405161012691906109bc565b60405180910390f35b61014960048036038101906101449190610a30565b6104c5565b6040516101569190610adf565b60405180910390f35b61016833610463565b156101aa57336040517f93360fbf0000000000000000000000000000000000000000000000000000000081526004016101a19190610b09565b60405180910390fd5b60016000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055505050565b6040517fcf9e0d0100000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b600080610243836105ca565b905060006102ad8580610100019061025b9190610b33565b8080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f82011690508083019250505050505050836105fc90919063ffffffff16565b9050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16148061036157503373ffffffffffffffffffffffffffffffffffffffff16632f54bf6e826040518263ffffffff1660e01b815260040161031e9190610b09565b602060405180830381865afa15801561033b573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061035f9190610bc2565b155b156103715760019250505061045d565b60008580606001906103839190610b33565b60009060049261039593929190610bf9565b906103a09190610c4c565b905060008680606001906103b49190610b33565b60048181106103c6576103c5610cab565b5b9050013560f81c60f81b90503660008880606001906103e59190610b33565b60249080926103f693929190610bf9565b9150915061040883600160f81b610697565b156104255736600061041a84846106e8565b915091505050610456565b61043383600060f81b610697565b15610455576000803660006104488686610701565b9350935093509350505050505b5b5050505050505b92915050565b60008060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff169050919050565b6000600182149050919050565b6000806104d1856105ca565b905060006105238286868080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050506105fc565b90503373ffffffffffffffffffffffffffffffffffffffff16632f54bf6e826040518263ffffffff1660e01b815260040161055e9190610b09565b602060405180830381865afa15801561057b573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061059f9190610bc2565b156105b557631626ba7e60e01b925050506105c2565b63ffffffff60e01b925050505b949350505050565b6000816020527b19457468657265756d205369676e6564204d6573736167653a0a3332600052603c6004209050919050565b600060019050604051600115610666578360005260208301516040526040835103610640576040830151601b8160ff1c016020528060011b60011c60605250610666565b604183510361066157606083015160001a6020526040830151606052610666565b600091505b6020600160806000855afa5191503d61068757638baa579f6000526004601cfd5b6000606052806040525092915050565b6000817effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916837effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff191614905092915050565b3660008335840160208101925080359150509250929050565b600080366000858560009060149261071b93929190610bf9565b906107269190610d06565b60601c9350858560149060349261073f93929190610bf9565b9061074a9190610d65565b60001c92508585603490809261076293929190610bf9565b9150915092959194509250565b600080fd5b600080fd5b600080fd5b600080fd5b600080fd5b60008083601f84011261079e5761079d610779565b5b8235905067ffffffffffffffff8111156107bb576107ba61077e565b5b6020830191508360018202830111156107d7576107d6610783565b5b9250929050565b600080602083850312156107f5576107f461076f565b5b600083013567ffffffffffffffff81111561081357610812610774565b5b61081f85828601610788565b92509250509250929050565b600080fd5b600061012082840312156108475761084661082b565b5b81905092915050565b6000819050919050565b61086381610850565b811461086e57600080fd5b50565b6000813590506108808161085a565b92915050565b6000806040838503121561089d5761089c61076f565b5b600083013567ffffffffffffffff8111156108bb576108ba610774565b5b6108c785828601610830565b92505060206108d885828601610871565b9150509250929050565b6000819050919050565b6108f5816108e2565b82525050565b600060208201905061091060008301846108ec565b92915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061094182610916565b9050919050565b61095181610936565b811461095c57600080fd5b50565b60008135905061096e81610948565b92915050565b60006020828403121561098a5761098961076f565b5b60006109988482850161095f565b91505092915050565b60008115159050919050565b6109b6816109a1565b82525050565b60006020820190506109d160008301846109ad565b92915050565b6109e0816108e2565b81146109eb57600080fd5b50565b6000813590506109fd816109d7565b92915050565b600060208284031215610a1957610a1861076f565b5b6000610a27848285016109ee565b91505092915050565b60008060008060608587031215610a4a57610a4961076f565b5b6000610a588782880161095f565b9450506020610a6987828801610871565b935050604085013567ffffffffffffffff811115610a8a57610a89610774565b5b610a9687828801610788565b925092505092959194509250565b60007fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b610ad981610aa4565b82525050565b6000602082019050610af46000830184610ad0565b92915050565b610b0381610936565b82525050565b6000602082019050610b1e6000830184610afa565b92915050565b600080fd5b600080fd5b600080fd5b60008083356001602003843603038112610b5057610b4f610b24565b5b80840192508235915067ffffffffffffffff821115610b7257610b71610b29565b5b602083019250600182023603831315610b8e57610b8d610b2e565b5b509250929050565b610b9f816109a1565b8114610baa57600080fd5b50565b600081519050610bbc81610b96565b92915050565b600060208284031215610bd857610bd761076f565b5b6000610be684828501610bad565b91505092915050565b600080fd5b600080fd5b60008085851115610c0d57610c0c610bef565b5b83861115610c1e57610c1d610bf4565b5b6001850283019150848603905094509492505050565b600082905092915050565b600082821b905092915050565b6000610c588383610c34565b82610c638135610aa4565b92506004821015610ca357610c9e7fffffffff0000000000000000000000000000000000000000000000000000000083600403600802610c3f565b831692505b505092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b60007fffffffffffffffffffffffffffffffffffffffff00000000000000000000000082169050919050565b6000610d128383610c34565b82610d1d8135610cda565b92506014821015610d5d57610d587fffffffffffffffffffffffffffffffffffffffff00000000000000000000000083601403600802610c3f565b831692505b505092915050565b6000610d718383610c34565b82610d7c8135610850565b92506020821015610dbc57610db77fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff83602003600802610c3f565b831692505b50509291505056fea2646970667358221220ee58404ea99d2deee0b084158c9f28570fe6daa74661d6fffa0eef7863ad6a3b64736f6c63430008170033';

type MultipleOwnerECDSAValidatorConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: MultipleOwnerECDSAValidatorConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class MultipleOwnerECDSAValidator__factory extends ContractFactory {
  constructor(...args: MultipleOwnerECDSAValidatorConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<MultipleOwnerECDSAValidator> {
    return super.deploy(
      overrides || {}
    ) as Promise<MultipleOwnerECDSAValidator>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): MultipleOwnerECDSAValidator {
    return super.attach(address) as MultipleOwnerECDSAValidator;
  }
  override connect(signer: Signer): MultipleOwnerECDSAValidator__factory {
    return super.connect(signer) as MultipleOwnerECDSAValidator__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MultipleOwnerECDSAValidatorInterface {
    return new utils.Interface(_abi) as MultipleOwnerECDSAValidatorInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MultipleOwnerECDSAValidator {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as MultipleOwnerECDSAValidator;
  }
}
