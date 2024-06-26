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
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../../../../common";

export type ExecutionStruct = {
  target: PromiseOrValue<string>;
  value: PromiseOrValue<BigNumberish>;
  callData: PromiseOrValue<BytesLike>;
};

export type ExecutionStructOutput = [string, BigNumber, string] & {
  target: string;
  value: BigNumber;
  callData: string;
};

export interface MockExecutorInterface extends utils.Interface {
  functions: {
    "execBatch(address,(address,uint256,bytes)[])": FunctionFragment;
    "execDelegatecall(address,bytes)": FunctionFragment;
    "executeViaAccount(address,address,uint256,bytes)": FunctionFragment;
    "isInitialized(address)": FunctionFragment;
    "isModuleType(uint256)": FunctionFragment;
    "onInstall(bytes)": FunctionFragment;
    "onUninstall(bytes)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "execBatch"
      | "execDelegatecall"
      | "executeViaAccount"
      | "isInitialized"
      | "isModuleType"
      | "onInstall"
      | "onUninstall"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "execBatch",
    values: [PromiseOrValue<string>, ExecutionStruct[]]
  ): string;
  encodeFunctionData(
    functionFragment: "execDelegatecall",
    values: [PromiseOrValue<string>, PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "executeViaAccount",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "isInitialized",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "isModuleType",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "onInstall",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "onUninstall",
    values: [PromiseOrValue<BytesLike>]
  ): string;

  decodeFunctionResult(functionFragment: "execBatch", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "execDelegatecall",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "executeViaAccount",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isInitialized",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isModuleType",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "onInstall", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "onUninstall",
    data: BytesLike
  ): Result;

  events: {};
}

export interface MockExecutor extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: MockExecutorInterface;

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
    execBatch(
      account: PromiseOrValue<string>,
      execs: ExecutionStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    execDelegatecall(
      account: PromiseOrValue<string>,
      callData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    executeViaAccount(
      account: PromiseOrValue<string>,
      target: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      callData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isModuleType(
      moduleTypeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    onInstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    onUninstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  execBatch(
    account: PromiseOrValue<string>,
    execs: ExecutionStruct[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  execDelegatecall(
    account: PromiseOrValue<string>,
    callData: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  executeViaAccount(
    account: PromiseOrValue<string>,
    target: PromiseOrValue<string>,
    value: PromiseOrValue<BigNumberish>,
    callData: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  isInitialized(
    smartAccount: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isModuleType(
    moduleTypeId: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  onInstall(
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  onUninstall(
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    execBatch(
      account: PromiseOrValue<string>,
      execs: ExecutionStruct[],
      overrides?: CallOverrides
    ): Promise<string[]>;

    execDelegatecall(
      account: PromiseOrValue<string>,
      callData: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string[]>;

    executeViaAccount(
      account: PromiseOrValue<string>,
      target: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      callData: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string[]>;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isModuleType(
      moduleTypeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    onInstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    onUninstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    execBatch(
      account: PromiseOrValue<string>,
      execs: ExecutionStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    execDelegatecall(
      account: PromiseOrValue<string>,
      callData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    executeViaAccount(
      account: PromiseOrValue<string>,
      target: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      callData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isModuleType(
      moduleTypeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    onInstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    onUninstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    execBatch(
      account: PromiseOrValue<string>,
      execs: ExecutionStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    execDelegatecall(
      account: PromiseOrValue<string>,
      callData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    executeViaAccount(
      account: PromiseOrValue<string>,
      target: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      callData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isModuleType(
      moduleTypeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    onInstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    onUninstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
