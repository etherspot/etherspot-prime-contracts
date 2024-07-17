/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../common";
import type {
  ERC20SessionKeyValidator,
  ERC20SessionKeyValidatorInterface,
} from "../../../../../src/modular-etherspot-wallet/modules/validators/ERC20SessionKeyValidator";

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
    name: "ERC20SKV_InsufficientApprovalAmount",
    type: "error",
  },
  {
    inputs: [],
    name: "ERC20SKV_InvalidSessionKey",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "session",
        type: "address",
      },
    ],
    name: "ERC20SKV_SessionKeyDoesNotExist",
    type: "error",
  },
  {
    inputs: [],
    name: "ERC20SKV_SessionKeySpendLimitExceeded",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "sessionKey",
        type: "address",
      },
    ],
    name: "ERC20SKV_SessionPaused",
    type: "error",
  },
  {
    inputs: [],
    name: "ERC20SKV_UnsuportedToken",
    type: "error",
  },
  {
    inputs: [],
    name: "ERC20SKV_UnsupportedInterface",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "selectorUsed",
        type: "bytes4",
      },
    ],
    name: "ERC20SKV_UnsupportedSelector",
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
    inputs: [],
    name: "NotImplemented",
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
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "sessionKey",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "wallet",
        type: "address",
      },
    ],
    name: "ERC20SKV_SessionKeyDisabled",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "sessionKey",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "wallet",
        type: "address",
      },
    ],
    name: "ERC20SKV_SessionKeyEnabled",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_sessionKey",
        type: "address",
      },
    ],
    name: "checkSessionKeyPaused",
    outputs: [
      {
        internalType: "bool",
        name: "paused",
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
        name: "_session",
        type: "address",
      },
    ],
    name: "disableSessionKey",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
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
        internalType: "bytes",
        name: "_sessionData",
        type: "bytes",
      },
    ],
    name: "enableSessionKey",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "getAssociatedSessionKeys",
    outputs: [
      {
        internalType: "address[]",
        name: "keys",
        type: "address[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_sessionKey",
        type: "address",
      },
    ],
    name: "getSessionKeyData",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "token",
            type: "address",
          },
          {
            internalType: "bytes4",
            name: "interfaceId",
            type: "bytes4",
          },
          {
            internalType: "bytes4",
            name: "funcSelector",
            type: "bytes4",
          },
          {
            internalType: "uint256",
            name: "spendingLimit",
            type: "uint256",
          },
          {
            internalType: "uint48",
            name: "validAfter",
            type: "uint48",
          },
          {
            internalType: "uint48",
            name: "validUntil",
            type: "uint48",
          },
          {
            internalType: "bool",
            name: "paused",
            type: "bool",
          },
        ],
        internalType: "struct IERC20SessionKeyValidator.SessionData",
        name: "data",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "initialized",
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
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "sender",
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
        internalType: "address",
        name: "_oldSessionKey",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "_newSessionData",
        type: "bytes",
      },
    ],
    name: "rotateSessionKey",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "sessionKey",
        type: "address",
      },
      {
        internalType: "address",
        name: "wallet",
        type: "address",
      },
    ],
    name: "sessionData",
    outputs: [
      {
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
      {
        internalType: "bytes4",
        name: "funcSelector",
        type: "bytes4",
      },
      {
        internalType: "uint256",
        name: "spendingLimit",
        type: "uint256",
      },
      {
        internalType: "uint48",
        name: "validAfter",
        type: "uint48",
      },
      {
        internalType: "uint48",
        name: "validUntil",
        type: "uint48",
      },
      {
        internalType: "bool",
        name: "paused",
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
        name: "_sessionKey",
        type: "address",
      },
    ],
    name: "toggleSessionKeyPause",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_sessionKey",
        type: "address",
      },
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
    ],
    name: "validateSessionKeyParams",
    outputs: [
      {
        internalType: "bool",
        name: "valid",
        type: "bool",
      },
    ],
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
        name: "validationData",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "wallet",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    name: "walletSessionKeys",
    outputs: [
      {
        internalType: "address",
        name: "assocSessionKeys",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x61012060405234801561001157600080fd5b50306080524660a052606080610073604080518082018252601881527f455243323053657373696f6e4b657956616c696461746f720000000000000000602080830191909152825180840190935260058352640312e302e360dc1b9083015291565b815160209283012081519183019190912060c082905260e0819052604080517f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f8152938401929092529082015246606082015230608082015260a0902061010052506100dc9050565b60805160a05160c05160e0516101005161166d610111600039600050506000505060005050600050506000505061166d6000f3fe608060405234801561001057600080fd5b50600436106101165760003560e01c8063c037ee19116100a2578063d60b347f11610071578063d60b347f146104d0578063d8d38e42146104e3578063e08dd008146104f6578063ecd059611461050b578063f551e2ee1461051f57600080fd5b8063c037ee1914610464578063c602e59c14610487578063cbca47db1461049a578063cc8cbd28146104bd57600080fd5b80636d61fe70116100e95780636d61fe70146103be57806384b0196e146103ea5780638a91b0e3146104055780638aaa6a4014610418578063970032031461044357600080fd5b8063110891c11461011b57806320cbdcc614610285578063495079a0146102d857806352721fdd146102eb575b600080fd5b610205610129366004611137565b6040805160e081018252600080825260208201819052918101829052606081018290526080810182905260a0810182905260c0810191909152506001600160a01b039081166000908152600260208181526040808420338552825292839020835160e08082018652825496871682526001600160e01b0319600160a01b8804821b811694830194909452600160c01b90960490951b9091169284019290925260018201546060840152015465ffffffffffff8082166080840152600160301b82041660a083015260ff600160601b90910416151560c082015290565b6040805182516001600160a01b031681526020808401516001600160e01b0319908116918301919091528383015116918101919091526060808301519082015260808083015165ffffffffffff9081169183019190915260a0808401519091169082015260c09182015115159181019190915260e0015b60405180910390f35b6102d6610293366004611137565b6001600160a01b0316600090815260026020818152604080842033855290915290912001805460ff60601b198116600160601b9182900460ff1615909102179055565b005b6102d66102e63660046111a2565b610546565b6103646102f93660046111e4565b600260208181526000938452604080852090915291835291208054600182015491909201546001600160a01b03831692600160a01b810460e090811b93600160c01b909204901b9165ffffffffffff80821691600160301b810490911690600160601b900460ff1687565b604080516001600160a01b039890981688526001600160e01b031996871660208901529490951693860193909352606085019190915265ffffffffffff90811660808501521660a0830152151560c082015260e00161027c565b6102d66103cc3660046111a2565b5050336000908152602081905260409020805460ff19166001179055565b6103f2610876565b60405161027c979695949392919061125d565b6102d66104133660046111a2565b61089d565b61042b6104263660046112f6565b61094c565b6040516001600160a01b03909116815260200161027c565b610456610451366004611339565b610984565b60405190815260200161027c565b61047761047236600461137e565b610abc565b604051901515815260200161027c565b6102d66104953660046113cc565b610ce3565b6104776104a8366004611137565b60006020819052908152604090205460ff1681565b6104776104cb366004611137565b610cfb565b6104776104de366004611137565b610d2d565b6102d66104f1366004611137565b610d48565b6104fe610e32565b60405161027c919061141f565b61047761051936600461146c565b60011490565b61052d6104de366004611485565b6040516001600160e01b0319909116815260200161027c565b600061055560148284866114df565b61055e91611509565b60601c905060006105736028601485876114df565b61057c91611509565b60601c90506000610591602c602886886114df565b61059a9161153e565b905060006105ac6030602c87896114df565b6105b59161153e565b905060006105c760506030888a6114df565b6105d09161156c565b905060006105e260566050898b6114df565b6105eb9161158a565b60d01c90506000610600605c60568a8c6114df565b6106099161158a565b60d01c90506040518060e00160405280876001600160a01b03168152602001866001600160e01b0319168152602001856001600160e01b03191681526020018481526020018365ffffffffffff1681526020018265ffffffffffff1681526020016000151581525060026000896001600160a01b03166001600160a01b031681526020019081526020016000206000336001600160a01b03166001600160a01b0316815260200190815260200160002060008201518160000160006101000a8154816001600160a01b0302191690836001600160a01b0316021790555060208201518160000160146101000a81548163ffffffff021916908360e01c021790555060408201518160000160186101000a81548163ffffffff021916908360e01c02179055506060820151816001015560808201518160020160006101000a81548165ffffffffffff021916908365ffffffffffff16021790555060a08201518160020160066101000a81548165ffffffffffff021916908365ffffffffffff16021790555060c082015181600201600c6101000a81548160ff02191690831515021790555090505060016000336001600160a01b03166001600160a01b03168152602001908152602001600020879080600181540180825580915050600190039060005260206000200160009091909190916101000a8154816001600160a01b0302191690836001600160a01b031602179055507f3c8d6097a1246293dc66a3eeb0db267cb28a5b6c3367e2de5f331659222eb1ff87336040516108639291906001600160a01b0392831681529116602082015260400190565b60405180910390a1505050505050505050565b600f60f81b606080600080808361088b610e9d565b97989097965046955030945091925090565b60006108a7610e32565b905060005b815181101561092f57600260008383815181106108cb576108cb6115b8565b6020908102919091018101516001600160a01b031682528181019290925260409081016000908120338252909252812080546001600160e01b031916815560018082019290925560020180546cffffffffffffffffffffffffff19169055016108ac565b5050336000908152602081905260409020805460ff191690555050565b6001602052816000526040600020818154811061096857600080fd5b6000918252602090912001546001600160a01b03169150829050565b60008061098f610ef0565b60405161190160f01b6020820152602281018290526042810185905290915060009060620160405160208183030381529060405280519060200120905060006109fd826020527b19457468657265756d205369676e6564204d6573736167653a0a3332600052603c60042090565b90506000610a4d82610a136101008a018a6115ce565b8080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250610f7392505050565b9050610a598188610abc565b610a6a576001945050505050610ab6565b6001600160a01b03811660009081526002602081815260408084203385529091528220908101549091610aae9165ffffffffffff600160301b820481169116611004565b955050505050505b92915050565b60003681610acd60608501856115ce565b915091506000806000806000610ae3878761103c565b6001600160a01b038f16600090815260026020818152604080842033855290915290912090810154959a509398509196509450925090600160301b900465ffffffffffff161580610b475750600281015442600160301b90910465ffffffffffff16105b15610b6557604051636ed16c7960e01b815260040160405180910390fd5b80546001600160a01b03868116911614610b925760405163218d2fb360e11b815260040160405180910390fd5b80546040516301ffc9a760e01b8152600160a01b90910460e01b6001600160e01b03191660048201526001600160a01b038616906301ffc9a790602401602060405180830381865afa158015610bec573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610c109190611615565b1515600003610c3257604051630863587160e11b815260040160405180910390fd5b80546001600160e01b0319878116600160c01b90920460e01b1614610c7b5760405163a47eb18d60e01b81526001600160e01b0319871660048201526024015b60405180910390fd5b8060010154821115610ca057604051638d6d48cb60e01b815260040160405180910390fd5b610ca98b610cfb565b15610cd2576040516374d12a8360e01b81526001600160a01b038c166004820152602401610c72565b5060019a9950505050505050505050565b610cec83610d48565b610cf68282610546565b505050565b6001600160a01b031660009081526002602081815260408084203385529091529091200154600160601b900460ff1690565b600060405163d623472560e01b815260040160405180910390fd5b6001600160a01b038116600090815260026020818152604080842033855290915282200154600160301b900465ffffffffffff169003610da6576040516315aab36760e31b81526001600160a01b0382166004820152602401610c72565b6001600160a01b03811660008181526002602081815260408084203380865290835281852080546001600160e01b031916815560018101959095559390920180546cffffffffffffffffffffffffff1916905581519384528301919091527f3552ecdbdb725cc8b621be8a316008bbcb5bc1e72e9a6b08da9b20bd7f78266d910160405180910390a150565b33600090815260016020908152604091829020805483518184028101840190945280845260609392830182828015610e9357602002820191906000526020600020905b81546001600160a01b03168152600190910190602001808311610e75575b5050505050905090565b604080518082018252601881527f455243323053657373696f6e4b657956616c696461746f720000000000000000602080830191909152825180840190935260058352640312e302e360dc1b9083015291565b6000806000610efd610e9d565b8151602092830120815191830191909120604080517f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f818601528082019390935260608301919091524660808301523060a0808401919091528151808403909101815260c0909201905280519101209392505050565b6040516001908360005260208301516040526040835103610faf57604083015160ff81901c601b016020526001600160ff1b0316606052610fd5565b6041835103610fd057606083015160001a6020526040830151606052610fd5565b600091505b6020600160806000855afa5191503d610ff657638baa579f6000526004601cfd5b600060605260405292915050565b600060d08265ffffffffffff16901b60a08465ffffffffffff16901b8561102c57600061102f565b60015b60ff161717949350505050565b6000600483013581808086356001600160e01b0319811663095ea7b360e01b148061107757506001600160e01b0319811663a9059cbb60e01b145b8061109257506001600160e01b0319811663010a5c0b60e41b145b156110b457945050505060048401359050602484013560006044860135611111565b63dc478d2360e01b6001600160e01b03198216016110ec57945050505060048401359050604484013560248501356064860135611111565b60405163a47eb18d60e01b81526001600160e01b031982166004820152602401610c72565b9295509295909350565b80356001600160a01b038116811461113257600080fd5b919050565b60006020828403121561114957600080fd5b6111528261111b565b9392505050565b60008083601f84011261116b57600080fd5b50813567ffffffffffffffff81111561118357600080fd5b60208301915083602082850101111561119b57600080fd5b9250929050565b600080602083850312156111b557600080fd5b823567ffffffffffffffff8111156111cc57600080fd5b6111d885828601611159565b90969095509350505050565b600080604083850312156111f757600080fd5b6112008361111b565b915061120e6020840161111b565b90509250929050565b6000815180845260005b8181101561123d57602081850181015186830182015201611221565b506000602082860101526020601f19601f83011685010191505092915050565b60ff60f81b881681526000602060e0602084015261127e60e084018a611217565b8381036040850152611290818a611217565b606085018990526001600160a01b038816608086015260a0850187905284810360c08601528551808252602080880193509091019060005b818110156112e4578351835292840192918401916001016112c8565b50909c9b505050505050505050505050565b6000806040838503121561130957600080fd5b6113128361111b565b946020939093013593505050565b6000610120828403121561133357600080fd5b50919050565b6000806040838503121561134c57600080fd5b823567ffffffffffffffff81111561136357600080fd5b61136f85828601611320565b95602094909401359450505050565b6000806040838503121561139157600080fd5b61139a8361111b565b9150602083013567ffffffffffffffff8111156113b657600080fd5b6113c285828601611320565b9150509250929050565b6000806000604084860312156113e157600080fd5b6113ea8461111b565b9250602084013567ffffffffffffffff81111561140657600080fd5b61141286828701611159565b9497909650939450505050565b6020808252825182820181905260009190848201906040850190845b818110156114605783516001600160a01b03168352928401929184019160010161143b565b50909695505050505050565b60006020828403121561147e57600080fd5b5035919050565b6000806000806060858703121561149b57600080fd5b6114a48561111b565b935060208501359250604085013567ffffffffffffffff8111156114c757600080fd5b6114d387828801611159565b95989497509550505050565b600080858511156114ef57600080fd5b838611156114fc57600080fd5b5050820193919092039150565b6bffffffffffffffffffffffff1981358181169160148510156115365780818660140360031b1b83161692505b505092915050565b6001600160e01b031981358181169160048510156115365760049490940360031b84901b1690921692915050565b80356020831015610ab657600019602084900360031b1b1692915050565b6001600160d01b031981358181169160068510156115365760069490940360031b84901b1690921692915050565b634e487b7160e01b600052603260045260246000fd5b6000808335601e198436030181126115e557600080fd5b83018035915067ffffffffffffffff82111561160057600080fd5b60200191503681900382131561119b57600080fd5b60006020828403121561162757600080fd5b8151801515811461115257600080fdfea26469706673582212209f46ad43dd681b3e0658ff7c2e12a3ddf75498869405bdc7aa37502de277c79f64736f6c63430008170033";

type ERC20SessionKeyValidatorConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: ERC20SessionKeyValidatorConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class ERC20SessionKeyValidator__factory extends ContractFactory {
  constructor(...args: ERC20SessionKeyValidatorConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ERC20SessionKeyValidator> {
    return super.deploy(overrides || {}) as Promise<ERC20SessionKeyValidator>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): ERC20SessionKeyValidator {
    return super.attach(address) as ERC20SessionKeyValidator;
  }
  override connect(signer: Signer): ERC20SessionKeyValidator__factory {
    return super.connect(signer) as ERC20SessionKeyValidator__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ERC20SessionKeyValidatorInterface {
    return new utils.Interface(_abi) as ERC20SessionKeyValidatorInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ERC20SessionKeyValidator {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as ERC20SessionKeyValidator;
  }
}
