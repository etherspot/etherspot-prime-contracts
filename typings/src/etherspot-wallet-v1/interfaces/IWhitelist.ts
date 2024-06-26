/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
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

export interface IWhitelistInterface extends utils.Interface {
  functions: {
    "addBatchToWhitelist(address[])": FunctionFragment;
    "addToWhitelist(address)": FunctionFragment;
    "check(address,address)": FunctionFragment;
    "removeBatchFromWhitelist(address[])": FunctionFragment;
    "removeFromWhitelist(address)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "addBatchToWhitelist"
      | "addToWhitelist"
      | "check"
      | "removeBatchFromWhitelist"
      | "removeFromWhitelist"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "addBatchToWhitelist",
    values: [PromiseOrValue<string>[]]
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
    functionFragment: "removeBatchFromWhitelist",
    values: [PromiseOrValue<string>[]]
  ): string;
  encodeFunctionData(
    functionFragment: "removeFromWhitelist",
    values: [PromiseOrValue<string>]
  ): string;

  decodeFunctionResult(
    functionFragment: "addBatchToWhitelist",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "addToWhitelist",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "check", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "removeBatchFromWhitelist",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "removeFromWhitelist",
    data: BytesLike
  ): Result;

  events: {
    "AddedBatchToWhitelist(address,address[])": EventFragment;
    "AddedToWhitelist(address,address)": EventFragment;
    "RemovedBatchFromWhitelist(address,address[])": EventFragment;
    "RemovedFromWhitelist(address,address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "AddedBatchToWhitelist"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "AddedToWhitelist"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RemovedBatchFromWhitelist"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RemovedFromWhitelist"): EventFragment;
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

export interface IWhitelist extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IWhitelistInterface;

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

    addToWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    check(
      _sponsor: PromiseOrValue<string>,
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    removeBatchFromWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    removeFromWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  addBatchToWhitelist(
    _accounts: PromiseOrValue<string>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
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

  removeBatchFromWhitelist(
    _accounts: PromiseOrValue<string>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  removeFromWhitelist(
    _account: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    addBatchToWhitelist(
      _accounts: PromiseOrValue<string>[],
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

    removeBatchFromWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: CallOverrides
    ): Promise<void>;

    removeFromWhitelist(
      _account: PromiseOrValue<string>,
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
  };

  estimateGas: {
    addBatchToWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
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

    removeBatchFromWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    removeFromWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    addBatchToWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
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

    removeBatchFromWhitelist(
      _accounts: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    removeFromWhitelist(
      _account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
