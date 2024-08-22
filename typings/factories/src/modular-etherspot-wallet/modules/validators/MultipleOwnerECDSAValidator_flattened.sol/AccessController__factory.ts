/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../../common";
import type {
  AccessController,
  AccessControllerInterface,
} from "../../../../../../src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator_flattened.sol/AccessController";

const _abi = [
  {
    inputs: [],
    name: "AddingInvalidGuardian",
    type: "error",
  },
  {
    inputs: [],
    name: "AddingInvalidOwner",
    type: "error",
  },
  {
    inputs: [],
    name: "AlreadySignedProposal",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidProposal",
    type: "error",
  },
  {
    inputs: [],
    name: "NotEnoughGuardians",
    type: "error",
  },
  {
    inputs: [],
    name: "OnlyGuardian",
    type: "error",
  },
  {
    inputs: [],
    name: "OnlyOwnerOrGuardianOrSelf",
    type: "error",
  },
  {
    inputs: [],
    name: "OnlyOwnerOrSelf",
    type: "error",
  },
  {
    inputs: [],
    name: "ProposalResolved",
    type: "error",
  },
  {
    inputs: [],
    name: "ProposalTimelocked",
    type: "error",
  },
  {
    inputs: [],
    name: "ProposalUnresolved",
    type: "error",
  },
  {
    inputs: [],
    name: "RemovingInvalidGuardian",
    type: "error",
  },
  {
    inputs: [],
    name: "RemovingInvalidOwner",
    type: "error",
  },
  {
    inputs: [],
    name: "WalletNeedsOwner",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "newGuardian",
        type: "address",
      },
    ],
    name: "GuardianAdded",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "removedGuardian",
        type: "address",
      },
    ],
    name: "GuardianRemoved",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnerAdded",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "removedOwner",
        type: "address",
      },
    ],
    name: "OwnerRemoved",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "proposalId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "discardedBy",
        type: "address",
      },
    ],
    name: "ProposalDiscarded",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "proposalId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "newOwnerProposed",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "proposer",
        type: "address",
      },
    ],
    name: "ProposalSubmitted",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "proposalId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "newOwnerProposed",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "approvalCount",
        type: "uint256",
      },
    ],
    name: "QuorumNotReached",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_newGuardian",
        type: "address",
      },
    ],
    name: "addGuardian",
    outputs: [],
    stateMutability: "nonpayable",
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
    name: "addOwner",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_newTimelock",
        type: "uint256",
      },
    ],
    name: "changeProposalTimelock",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "discardCurrentProposal",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_proposalId",
        type: "uint256",
      },
    ],
    name: "getProposal",
    outputs: [
      {
        internalType: "address",
        name: "ownerProposed_",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "approvalCount_",
        type: "uint256",
      },
      {
        internalType: "address[]",
        name: "guardiansApproved_",
        type: "address[]",
      },
      {
        internalType: "bool",
        name: "resolved_",
        type: "bool",
      },
      {
        internalType: "uint256",
        name: "proposedAt_",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "guardianCosign",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "guardianCount",
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
        internalType: "address",
        name: "_newOwner",
        type: "address",
      },
    ],
    name: "guardianPropose",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_address",
        type: "address",
      },
    ],
    name: "isGuardian",
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
        name: "_address",
        type: "address",
      },
    ],
    name: "isOwner",
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
    name: "ownerCount",
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
    name: "proposalId",
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
    name: "proposalTimelock",
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
        internalType: "address",
        name: "_guardian",
        type: "address",
      },
    ],
    name: "removeGuardian",
    outputs: [],
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
    ],
    name: "removeOwner",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b50610e75806100206000396000f3fe608060405234801561001057600080fd5b50600436106100f55760003560e01c80637065cb4811610097578063a526d83b11610066578063a526d83b146101c7578063bf57159b146101da578063c3db8838146101e3578063c7f758a8146101eb57600080fd5b80637065cb481461017b578063714041561461018e5780637dcab4ce146101a1578063a1c0d459146101b457600080fd5b80632dfca445116100d35780632dfca4451461014e5780632f54bf6e1461015757806341c9ddff1461016a57806354387ad71461017257600080fd5b80630c68ba21146100fa5780630db0262214610122578063173825d914610139575b600080fd5b61010d610108366004610cdb565b61020f565b60405190151581526020015b60405180910390f35b61012b60005481565b604051908152602001610119565b61014c610147366004610cdb565b61022d565b005b61012b60025481565b61010d610165366004610cdb565b6102f4565b61014c610312565b61012b60015481565b61014c610189366004610cdb565b6104cf565b61014c61019c366004610cdb565b61058d565b61014c6101af366004610cdb565b61062a565b61014c6101c2366004610d0b565b6107ef565b61014c6101d5366004610cdb565b610824565b61012b60035481565b61014c6108e2565b6101fe6101f9366004610d0b565b610a25565b604051610119959493929190610d24565b6001600160a01b031660009081526005602052604090205460ff1690565b610236336102f4565b8061024057503330145b61025d576040516311d9f09160e01b815260040160405180910390fd5b610266816102f4565b6102835760405163f1369ccb60e01b815260040160405180910390fd5b6001600054116102a65760405163021870b960e11b815260040160405180910390fd5b6102af81610b2f565b604080513081526001600160a01b03831660208201527fe594d081b4382713733fe631966432c9cea5199afb2db5c3c1931f9f9300367991015b60405180910390a150565b6001600160a01b031660009081526004602052604090205460ff1690565b61031b3361020f565b61033857604051636570ecab60e11b815260040160405180910390fd5b60025460008181526006602052604081209082900361036a57604051631dc0650160e31b815260040160405180910390fd5b61037382610b64565b15610391576040516320181a3560e21b815260040160405180910390fd5b6103b3600254600090815260066020526040902054600160a01b900460ff1690565b156103d157604051638b19dbcb60e01b815260040160405180910390fd5b60008281526006602090815260408220600180820180549182018155845291832090910180546001600160a01b0319163317905583825260020180549161041783610da7565b909155505080546001600160a01b031661043083610bdb565b15610462576000838152600660205260409020805460ff60a01b1916600160a01b17905561045d81610c15565b505050565b6000838152600660209081526040918290206002015482513081529182018690526001600160a01b0384169282019290925260608101919091527f7afa94f51443879f537b9be4f09d5d734c2c233b788d2f6af6565add34706bab906080015b60405180910390a1505050565b6104d8336102f4565b806104e257503330145b6104ff576040516311d9f09160e01b815260040160405180910390fd5b6001600160a01b038116158061051957506105198161020f565b806105285750610528816102f4565b1561054657604051631a1aefc560e21b815260040160405180910390fd5b61054f81610c15565b604080513081526001600160a01b03831660208201527fc82bdbbf677a2462f2a7e22e4ba9abd209496b69cd7b868b3b1d28f76e09a40a91016102e9565b610596336102f4565b806105a057503330145b6105bd576040516311d9f09160e01b815260040160405180910390fd5b6105c68161020f565b6105e35760405163985f453960e01b815260040160405180910390fd5b6105ec81610c45565b604080513081526001600160a01b03831660208201527fee943cdb81826d5909c559c6b1ae6908fcaf2dbc16c4b730346736b486283e8b91016102e9565b6106333361020f565b61065057604051636570ecab60e11b815260040160405180910390fd5b6001600160a01b038116158061066a575061066a8161020f565b806106795750610679816102f4565b1561069757604051631a1aefc560e21b815260040160405180910390fd5b600360015410156106bb57604051636bb07db960e11b815260040160405180910390fd5b60025460009081526006602052604090206001810154158015906106e857508054600160a01b900460ff16155b1561070657604051639fa6dc5760e01b815260040160405180910390fd5b600060025460016107179190610dc0565b6000818152600660209081526040822080546001600160a01b0388166001600160a01b031991821617825560018083018054918201815585529284209092018054909216331790915582825260020180549293509061077583610da7565b9091555050600081815260066020908152604091829020805460ff60a01b1916815542600390910155600283905581513081529081018390526001600160a01b038516918101919091523360608201527f9fb4a8d051aad8866705f4d52eb05a29939e15ad43dd4aab82cf31806759eac3906080016104c2565b6107f8336102f4565b8061080257503330145b61081f576040516311d9f09160e01b815260040160405180910390fd5b600355565b61082d336102f4565b8061083757503330145b610854576040516311d9f09160e01b815260040160405180910390fd5b6001600160a01b038116158061086e575061086e8161020f565b8061087d575061087d816102f4565b1561089b5760405163053bd11560e31b815260040160405180910390fd5b6108a481610ca9565b604080513081526001600160a01b03831660208201527fbc3292102fa77e083913064b282926717cdfaede4d35f553d66366c0a3da755a91016102e9565b6108eb336102f4565b806108fa57506108fa3361020f565b8061090457503330145b610921576040516302d8be6160e21b815260040160405180910390fd5b6002546000908152600660205260408120600354909190156109455760035461094a565b620151805b905061096e600254600090815260066020526040902054600160a01b900460ff1690565b1561098c57604051638b19dbcb60e01b815260040160405180910390fd5b60006109973361020f565b90508080156109b55750428284600301546109b29190610dc0565b10155b156109d35760405163ae18e9c760e01b815260040160405180910390fd5b825460ff60a01b1916600160a01b17835560025460408051308152602081019290925233908201527faf7f1090397448391393dc134b45d6d20e79a9d2a8f5a82fb42d1514a55ecbf9906060016104c2565b60008060608180851580610a3a575060025486115b15610a5857604051631dc0650160e31b815260040160405180910390fd5b6000868152600660209081526040808320815160a08101835281546001600160a01b0381168252600160a01b900460ff16151581850152600182018054845181870281018701865281815292959394860193830182828015610ae357602002820191906000526020600020905b81546001600160a01b03168152600190910190602001808311610ac5575b5050505050815260200160028201548152602001600382015481525050905080600001518160600151826040015183602001518460800151955095509550955095505091939590929450565b6001600160a01b0381166000908152600460205260408120805460ff1916905580549080610b5c83610dd9565b919050555050565b6000805b600083815260066020526040902060010154811015610bd2576000838152600660205260409020600101805433919083908110610ba757610ba7610df0565b6000918252602090912001546001600160a01b031603610bca5750600192915050565b600101610b68565b50600092915050565b600154600082815260066020526040812060020154909161025891610c03906103e890610e06565b610c0d9190610e1d565b101592915050565b6001600160a01b0381166000908152600460205260408120805460ff1916600117905580549080610b5c83610da7565b6001600160a01b0381166000908152600560205260408120805460ff191690556001805491610c7383610dd9565b9190505550610c9a600254600090815260066020526040902054600160a01b900460ff1690565b610ca657610ca66108e2565b50565b6001600160a01b0381166000908152600560205260408120805460ff19166001908117909155805491610c7383610da7565b600060208284031215610ced57600080fd5b81356001600160a01b0381168114610d0457600080fd5b9392505050565b600060208284031215610d1d57600080fd5b5035919050565b6001600160a01b038681168252602080830187905260a060408401819052865190840181905260009287830192909160c0860190855b81811015610d78578551851683529483019491830191600101610d5a565b5050961515606086015250505050608001529392505050565b634e487b7160e01b600052601160045260246000fd5b600060018201610db957610db9610d91565b5060010190565b80820180821115610dd357610dd3610d91565b92915050565b600081610de857610de8610d91565b506000190190565b634e487b7160e01b600052603260045260246000fd5b8082028115828204841417610dd357610dd3610d91565b600082610e3a57634e487b7160e01b600052601260045260246000fd5b50049056fea26469706673582212208bcc7742300c7cebb7ad4a93fb613830a9ee8b1ee3c1973a43de1c1699a79f8864736f6c63430008170033";

type AccessControllerConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: AccessControllerConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class AccessController__factory extends ContractFactory {
  constructor(...args: AccessControllerConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<AccessController> {
    return super.deploy(overrides || {}) as Promise<AccessController>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): AccessController {
    return super.attach(address) as AccessController;
  }
  override connect(signer: Signer): AccessController__factory {
    return super.connect(signer) as AccessController__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): AccessControllerInterface {
    return new utils.Interface(_abi) as AccessControllerInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): AccessController {
    return new Contract(address, _abi, signerOrProvider) as AccessController;
  }
}
