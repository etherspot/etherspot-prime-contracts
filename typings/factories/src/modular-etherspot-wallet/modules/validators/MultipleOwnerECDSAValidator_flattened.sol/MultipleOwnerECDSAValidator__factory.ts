/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../../common";
import type {
  MultipleOwnerECDSAValidator,
  MultipleOwnerECDSAValidatorInterface,
} from "../../../../../../src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator_flattened.sol/MultipleOwnerECDSAValidator";

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
    inputs: [],
    name: "InvalidExec",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "target",
        type: "address",
      },
    ],
    name: "InvalidTargetAddress",
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
    inputs: [],
    name: "eip712Domain",
    outputs: [
      {
        internalType: "bytes1",
        name: "fields",
        type: "bytes1",
      },
      {
        internalType: "string",
        name: "name",
        type: "string",
      },
      {
        internalType: "string",
        name: "version",
        type: "string",
      },
      {
        internalType: "uint256",
        name: "chainId",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "verifyingContract",
        type: "address",
      },
      {
        internalType: "bytes32",
        name: "salt",
        type: "bytes32",
      },
      {
        internalType: "uint256[]",
        name: "extensions",
        type: "uint256[]",
      },
    ],
    stateMutability: "view",
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
        name: "typeID",
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
    stateMutability: "pure",
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
        internalType: "bytes32",
        name: "hash",
        type: "bytes32",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "isValidSignatureWithSender",
    outputs: [
      {
        internalType: "bytes4",
        name: "",
        type: "bytes4",
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
            internalType: "bytes32",
            name: "accountGasLimits",
            type: "bytes32",
          },
          {
            internalType: "uint256",
            name: "preVerificationGas",
            type: "uint256",
          },
          {
            internalType: "bytes32",
            name: "gasFees",
            type: "bytes32",
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
        internalType: "struct PackedUserOperation",
        name: "userOp",
        type: "tuple",
      },
      {
        internalType: "bytes32",
        name: "userOpHash",
        type: "bytes32",
      },
    ],
    name: "validateUserOp",
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
] as const;

const _bytecode =
  "0x61012060405234801561001157600080fd5b50306080524660a052606080610073604080518082018252601b81527f4d756c7469706c654f776e6572454344534156616c696461746f720000000000602080830191909152825180840190935260058352640312e302e360dc1b9083015291565b815160209283012081519183019190912060c082905260e0819052604080517f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f8152938401929092529082015246606082015230608082015260a0902061010052506100dc9050565b60805160a05160c05160e05161010051610b2e6101116000396000505060005050600050506000505060005050610b2e6000f3fe608060405234801561001057600080fd5b506004361061007d5760003560e01c8063970032031161005b57806397003203146100ce578063d60b347f146100ef578063ecd059611461012b578063f551e2ee1461013f57600080fd5b80636d61fe701461008257806384b0196e146100975780638a91b0e3146100bb575b600080fd5b6100956100903660046107b1565b61016b565b005b61009f6101c1565b6040516100b29796959493929190610839565b60405180910390f35b6100956100c93660046107b1565b6101e8565b6100e16100dc3660046108d2565b610235565b6040519081526020016100b2565b61011b6100fd366004610939565b6001600160a01b031660009081526020819052604090205460ff1690565b60405190151581526020016100b2565b61011b61013936600461095b565b60011490565b61015261014d366004610974565b610457565b6040516001600160e01b031990911681526020016100b2565b3360009081526020819052604090205460ff16156101a3576040516393360fbf60e01b81523360048201526024015b60405180910390fd5b5050336000908152602081905260409020805460ff19166001179055565b600f60f81b60608060008080836101d66105b0565b97989097965046955030945091925090565b3360009081526020819052604090205460ff1661021a5760405163f91bd6f160e01b815233600482015260240161019a565b5050336000908152602081905260409020805460ff19169055565b600080610240610603565b60405161190160f01b6020820152602281018290526042810185905290915060009060620160405160208183030381529060405280519060200120905060006102ae826020527b19457468657265756d205369676e6564204d6573736167653a0a3332600052603c60042090565b905060006102fe826102c46101008a018a6109ce565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525061068692505050565b90506001600160a01b038116158061037b57506040516317aa5fb760e11b81526001600160a01b03821660048201523390632f54bf6e90602401602060405180830381865afa158015610355573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103799190610a15565b155b1561038d576001945050505050610451565b600061039c60608901896109ce565b6103ab91600491600091610a37565b6103b491610a61565b905060006103c560608a018a6109ce565b60048181106103d6576103d6610a91565b909101356001600160f81b031916915036905060006103f860608c018c6109ce565b610406916024908290610a37565b9092509050600160f81b6001600160f81b0319841614610448576001600160f81b031983166104485760008036600061043f8686610717565b50505050505050505b50505050505050505b92915050565b600080610462610603565b60405161190160f01b6020820152602281018290526042810187905290915060009060620160405160208183030381529060405280519060200120905060006104d0826020527b19457468657265756d205369676e6564204d6573736167653a0a3332600052603c60042090565b905060006105148288888080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525061068692505050565b6040516317aa5fb760e11b81526001600160a01b03821660048201529091503390632f54bf6e90602401602060405180830381865afa15801561055b573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061057f9190610a15565b156105985750630b135d3f60e11b93506105a892505050565b506001600160e01b031993505050505b949350505050565b604080518082018252601b81527f4d756c7469706c654f776e6572454344534156616c696461746f720000000000602080830191909152825180840190935260058352640312e302e360dc1b9083015291565b60008060006106106105b0565b8151602092830120815191830191909120604080517f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f818601528082019390935260608301919091524660808301523060a0808401919091528151808403909101815260c0909201905280519101209392505050565b60405160019083600052602083015160405260408351036106c257604083015160ff81901c601b016020526001600160ff1b03166060526106e8565b60418351036106e357606083015160001a60205260408301516060526106e8565b600091505b6020600160806000855afa5191503d61070957638baa579f6000526004601cfd5b600060605260405292915050565b60008036816107296014828789610a37565b61073291610aa7565b60601c9350610745603460148789610a37565b61074e91610ada565b925061075d8560348189610a37565b949793965094505050565b60008083601f84011261077a57600080fd5b50813567ffffffffffffffff81111561079257600080fd5b6020830191508360208285010111156107aa57600080fd5b9250929050565b600080602083850312156107c457600080fd5b823567ffffffffffffffff8111156107db57600080fd5b6107e785828601610768565b90969095509350505050565b6000815180845260005b81811015610819576020818501810151868301820152016107fd565b506000602082860101526020601f19601f83011685010191505092915050565b60ff60f81b881681526000602060e0602084015261085a60e084018a6107f3565b838103604085015261086c818a6107f3565b606085018990526001600160a01b038816608086015260a0850187905284810360c08601528551808252602080880193509091019060005b818110156108c0578351835292840192918401916001016108a4565b50909c9b505050505050505050505050565b600080604083850312156108e557600080fd5b823567ffffffffffffffff8111156108fc57600080fd5b8301610120818603121561090f57600080fd5b946020939093013593505050565b80356001600160a01b038116811461093457600080fd5b919050565b60006020828403121561094b57600080fd5b6109548261091d565b9392505050565b60006020828403121561096d57600080fd5b5035919050565b6000806000806060858703121561098a57600080fd5b6109938561091d565b935060208501359250604085013567ffffffffffffffff8111156109b657600080fd5b6109c287828801610768565b95989497509550505050565b6000808335601e198436030181126109e557600080fd5b83018035915067ffffffffffffffff821115610a0057600080fd5b6020019150368190038213156107aa57600080fd5b600060208284031215610a2757600080fd5b8151801515811461095457600080fd5b60008085851115610a4757600080fd5b83861115610a5457600080fd5b5050820193919092039150565b6001600160e01b03198135818116916004851015610a895780818660040360031b1b83161692505b505092915050565b634e487b7160e01b600052603260045260246000fd5b6bffffffffffffffffffffffff198135818116916014851015610a895760149490940360031b84901b1690921692915050565b8035602083101561045157600019602084900360031b1b169291505056fea2646970667358221220355139cc46b6288780f13b265daf680d90ff63faaed4085a7b0cf41b8cffdacc64736f6c63430008170033";

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
