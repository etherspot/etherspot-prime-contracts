/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PayableOverrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../../common";

export type PackedUserOperationStruct = {
  sender: PromiseOrValue<string>;
  nonce: PromiseOrValue<BigNumberish>;
  initCode: PromiseOrValue<BytesLike>;
  callData: PromiseOrValue<BytesLike>;
  accountGasLimits: PromiseOrValue<BytesLike>;
  preVerificationGas: PromiseOrValue<BigNumberish>;
  gasFees: PromiseOrValue<BytesLike>;
  paymasterAndData: PromiseOrValue<BytesLike>;
  signature: PromiseOrValue<BytesLike>;
};

export type PackedUserOperationStructOutput = [
  string,
  BigNumber,
  string,
  string,
  string,
  BigNumber,
  string,
  string,
  string
] & {
  sender: string;
  nonce: BigNumber;
  initCode: string;
  callData: string;
  accountGasLimits: string;
  preVerificationGas: BigNumber;
  gasFees: string;
  paymasterAndData: string;
  signature: string;
};

export interface IEtherspotPaymasterInterface extends utils.Interface {
  functions: {
    "addBatchToWhitelist(address[])": FunctionFragment;
    "addStake(uint32)": FunctionFragment;
    "addToWhitelist(address)": FunctionFragment;
    "check(address,address)": FunctionFragment;
    "depositFunds()": FunctionFragment;
    "getDeposit()": FunctionFragment;
    "getHash((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes),uint48,uint48)": FunctionFragment;
    "getSponsorBalance(address)": FunctionFragment;
    "parsePaymasterAndData(bytes)": FunctionFragment;
    "postOp(uint8,bytes,uint256)": FunctionFragment;
    "removeBatchFromWhitelist(address[])": FunctionFragment;
    "removeFromWhitelist(address)": FunctionFragment;
    "unlockStake()": FunctionFragment;
    "validatePaymasterUserOp((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes),bytes32,uint256)": FunctionFragment;
    "withdrawFunds(address,uint256)": FunctionFragment;
    "withdrawStake(address)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "addBatchToWhitelist"
      | "addStake"
      | "addToWhitelist"
      | "check"
      | "depositFunds"
      | "getDeposit"
      | "getHash"
      | "getSponsorBalance"
      | "parsePaymasterAndData"
      | "postOp"
      | "removeBatchFromWhitelist"
      | "removeFromWhitelist"
      | "unlockStake"
      | "validatePaymasterUserOp"
      | "withdrawFunds"
      | "withdrawStake"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "addBatchToWhitelist",
    values: [PromiseOrValue<string>[]]
  ): string;
  encodeFunctionData(
    functionFragment: "addStake",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "addToWhitelist",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "check",
    values: [PromiseOrValue<string>, PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "depositFunds",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getDeposit",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getHash",
    values: [
      PackedUserOperationStruct,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "getSponsorBalance",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "parsePaymasterAndData",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "postOp",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "removeBatchFromWhitelist",
    values: [PromiseOrValue<string>[]]
  ): string;
  encodeFunctionData(
    functionFragment: "removeFromWhitelist",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "unlockStake",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "validatePaymasterUserOp",
    values: [
      PackedUserOperationStruct,
      PromiseOrValue<BytesLike>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawFunds",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawStake",
    values: [PromiseOrValue<string>]
  ): string;

  decodeFunctionResult(
    functionFragment: "addBatchToWhitelist",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "addStake", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "addToWhitelist",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "check", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "depositFunds",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "getDeposit", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getHash", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getSponsorBalance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "parsePaymasterAndData",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "postOp", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "removeBatchFromWhitelist",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "removeFromWhitelist",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "unlockStake",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "validatePaymasterUserOp",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawFunds",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawStake",
    data: BytesLike
  ): Result;

  events: {
    "AddedBatchToWhitelist(address,address[])": EventFragment;
    "AddedToWhitelist(address,address)": EventFragment;
    "RemovedBatchFromWhitelist(address,address[])": EventFragment;
    "RemovedFromWhitelist(address,address)": EventFragment;
    "SponsorSuccessful(address,address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "AddedBatchToWhitelist"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "AddedToWhitelist"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RemovedBatchFromWhitelist"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RemovedFromWhitelist"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "SponsorSuccessful"): EventFragment;
}

export interface AddedBatchToWhitelistEventObject {
  paymaster: string;
  accounts: string[];
}
export type AddedBatchToWhitelistEvent = TypedEvent<
  [string, string[]],
  AddedBatchToWhitelistEventObject
>;

export type AddedBatchToWhitelistEventFilter =
  TypedEventFilter<AddedBatchToWhitelistEvent>;

export interface AddedToWhitelistEventObject {
  paymaster: string;
  account: string;
}
export type AddedToWhitelistEvent = TypedEvent<
  [string, string],
  AddedToWhitelistEventObject
>;

export type AddedToWhitelistEventFilter =
  TypedEventFilter<AddedToWhitelistEvent>;

export interface RemovedBatchFromWhitelistEventObject {
  paymaster: string;
  accounts: string[];
}
export type RemovedBatchFromWhitelistEvent = TypedEvent<
  [string, string[]],
  RemovedBatchFromWhitelistEventObject
>;

export type RemovedBatchFromWhitelistEventFilter =
  TypedEventFilter<RemovedBatchFromWhitelistEvent>;

export interface RemovedFromWhitelistEventObject {
  paymaster: string;
  account: string;
}
export type RemovedFromWhitelistEvent = TypedEvent<
  [string, string],
  RemovedFromWhitelistEventObject
>;

export type RemovedFromWhitelistEventFilter =
  TypedEventFilter<RemovedFromWhitelistEvent>;

export interface SponsorSuccessfulEventObject {
  paymaster: string;
  sender: string;
}
export type SponsorSuccessfulEvent = TypedEvent<
  [string, string],
  SponsorSuccessfulEventObject
>;

export type SponsorSuccessfulEventFilter =
  TypedEventFilter<SponsorSuccessfulEvent>;

export interface IEtherspotPaymaster extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IEtherspotPaymasterInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    addBatchToWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    addStake(
      unstakeDelaySec: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    addToWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    check(
      _sponsor: PromiseOrValue<string>,
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    depositFunds(
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    getDeposit(overrides?: CallOverrides): Promise<[BigNumber]>;

    getHash(
      userOp: PackedUserOperationStruct,
      validUntil: PromiseOrValue<BigNumberish>,
      validAfter: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    getSponsorBalance(
      _sponsor: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    parsePaymasterAndData(
      paymasterAndData: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<
      [number, number, string] & {
        validUntil: number;
        validAfter: number;
        signature: string;
      }
    >;

    postOp(
      mode: PromiseOrValue<BigNumberish>,
      context: PromiseOrValue<BytesLike>,
      actualGasCost: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    removeBatchFromWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    removeFromWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    unlockStake(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    validatePaymasterUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      maxCost: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    withdrawFunds(
      _sponsor: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    withdrawStake(
      withdrawAddress: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  addBatchToWhitelist(
    _accounts: PromiseOrValue<string>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  addStake(
    unstakeDelaySec: PromiseOrValue<BigNumberish>,
    overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  addToWhitelist(
    _account: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  check(
    _sponsor: PromiseOrValue<string>,
    _account: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  depositFunds(
    overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  getDeposit(overrides?: CallOverrides): Promise<BigNumber>;

  getHash(
    userOp: PackedUserOperationStruct,
    validUntil: PromiseOrValue<BigNumberish>,
    validAfter: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  getSponsorBalance(
    _sponsor: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  parsePaymasterAndData(
    paymasterAndData: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<
    [number, number, string] & {
      validUntil: number;
      validAfter: number;
      signature: string;
    }
  >;

  postOp(
    mode: PromiseOrValue<BigNumberish>,
    context: PromiseOrValue<BytesLike>,
    actualGasCost: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  removeBatchFromWhitelist(
    _accounts: PromiseOrValue<string>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  removeFromWhitelist(
    _account: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  unlockStake(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  validatePaymasterUserOp(
    userOp: PackedUserOperationStruct,
    userOpHash: PromiseOrValue<BytesLike>,
    maxCost: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  withdrawFunds(
    _sponsor: PromiseOrValue<string>,
    _amount: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  withdrawStake(
    withdrawAddress: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    addBatchToWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: CallOverrides
    ): Promise<void>;

    addStake(
      unstakeDelaySec: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    addToWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    check(
      _sponsor: PromiseOrValue<string>,
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    depositFunds(overrides?: CallOverrides): Promise<void>;

    getDeposit(overrides?: CallOverrides): Promise<BigNumber>;

    getHash(
      userOp: PackedUserOperationStruct,
      validUntil: PromiseOrValue<BigNumberish>,
      validAfter: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;

    getSponsorBalance(
      _sponsor: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    parsePaymasterAndData(
      paymasterAndData: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<
      [number, number, string] & {
        validUntil: number;
        validAfter: number;
        signature: string;
      }
    >;

    postOp(
      mode: PromiseOrValue<BigNumberish>,
      context: PromiseOrValue<BytesLike>,
      actualGasCost: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    removeBatchFromWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: CallOverrides
    ): Promise<void>;

    removeFromWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    unlockStake(overrides?: CallOverrides): Promise<void>;

    validatePaymasterUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      maxCost: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [string, BigNumber] & { context: string; validationData: BigNumber }
    >;

    withdrawFunds(
      _sponsor: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    withdrawStake(
      withdrawAddress: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "AddedBatchToWhitelist(address,address[])"(
      paymaster?: PromiseOrValue<string> | null,
      accounts?: PromiseOrValue<string>[] | null
    ): AddedBatchToWhitelistEventFilter;
    AddedBatchToWhitelist(
      paymaster?: PromiseOrValue<string> | null,
      accounts?: PromiseOrValue<string>[] | null
    ): AddedBatchToWhitelistEventFilter;

    "AddedToWhitelist(address,address)"(
      paymaster?: PromiseOrValue<string> | null,
      account?: PromiseOrValue<string> | null
    ): AddedToWhitelistEventFilter;
    AddedToWhitelist(
      paymaster?: PromiseOrValue<string> | null,
      account?: PromiseOrValue<string> | null
    ): AddedToWhitelistEventFilter;

    "RemovedBatchFromWhitelist(address,address[])"(
      paymaster?: PromiseOrValue<string> | null,
      accounts?: PromiseOrValue<string>[] | null
    ): RemovedBatchFromWhitelistEventFilter;
    RemovedBatchFromWhitelist(
      paymaster?: PromiseOrValue<string> | null,
      accounts?: PromiseOrValue<string>[] | null
    ): RemovedBatchFromWhitelistEventFilter;

    "RemovedFromWhitelist(address,address)"(
      paymaster?: PromiseOrValue<string> | null,
      account?: PromiseOrValue<string> | null
    ): RemovedFromWhitelistEventFilter;
    RemovedFromWhitelist(
      paymaster?: PromiseOrValue<string> | null,
      account?: PromiseOrValue<string> | null
    ): RemovedFromWhitelistEventFilter;

    "SponsorSuccessful(address,address)"(
      paymaster?: null,
      sender?: null
    ): SponsorSuccessfulEventFilter;
    SponsorSuccessful(
      paymaster?: null,
      sender?: null
    ): SponsorSuccessfulEventFilter;
  };

  estimateGas: {
    addBatchToWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    addStake(
      unstakeDelaySec: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    addToWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    check(
      _sponsor: PromiseOrValue<string>,
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    depositFunds(
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    getDeposit(overrides?: CallOverrides): Promise<BigNumber>;

    getHash(
      userOp: PackedUserOperationStruct,
      validUntil: PromiseOrValue<BigNumberish>,
      validAfter: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getSponsorBalance(
      _sponsor: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    parsePaymasterAndData(
      paymasterAndData: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    postOp(
      mode: PromiseOrValue<BigNumberish>,
      context: PromiseOrValue<BytesLike>,
      actualGasCost: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    removeBatchFromWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    removeFromWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    unlockStake(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    validatePaymasterUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      maxCost: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    withdrawFunds(
      _sponsor: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    withdrawStake(
      withdrawAddress: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    addBatchToWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    addStake(
      unstakeDelaySec: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    addToWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    check(
      _sponsor: PromiseOrValue<string>,
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    depositFunds(
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    getDeposit(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getHash(
      userOp: PackedUserOperationStruct,
      validUntil: PromiseOrValue<BigNumberish>,
      validAfter: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getSponsorBalance(
      _sponsor: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    parsePaymasterAndData(
      paymasterAndData: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    postOp(
      mode: PromiseOrValue<BigNumberish>,
      context: PromiseOrValue<BytesLike>,
      actualGasCost: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    removeBatchFromWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    removeFromWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    unlockStake(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    validatePaymasterUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      maxCost: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    withdrawFunds(
      _sponsor: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    withdrawStake(
      withdrawAddress: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
