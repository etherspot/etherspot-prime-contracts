/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IAccessController,
  IAccessControllerInterface,
} from "../../../../../../src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator_flattened.sol/IAccessController";

const _abi = [
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

export class IAccessController__factory {
  static readonly abi = _abi;
  static createInterface(): IAccessControllerInterface {
    return new utils.Interface(_abi) as IAccessControllerInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IAccessController {
    return new Contract(address, _abi, signerOrProvider) as IAccessController;
  }
}