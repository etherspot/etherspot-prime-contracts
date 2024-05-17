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
} from "../../../../common";

export type BootstrapConfigStruct = {
  module: PromiseOrValue<string>;
  data: PromiseOrValue<BytesLike>;
};

export type BootstrapConfigStructOutput = [string, string] & {
  module: string;
  data: string;
};

export declare namespace ModuleManager {
  export type FallbackHandlerStruct = {
    handler: PromiseOrValue<string>;
    calltype: PromiseOrValue<BytesLike>;
    allowedCallers: PromiseOrValue<string>[];
  };

  export type FallbackHandlerStructOutput = [string, string, string[]] & {
    handler: string;
    calltype: string;
    allowedCallers: string[];
  };
}

export interface BootstrapInterface extends utils.Interface {
  functions: {
    "_getInitMSACalldata((address,bytes)[],(address,bytes)[],(address,bytes),(address,bytes)[])": FunctionFragment;
    "entryPoint()": FunctionFragment;
    "getActiveFallbackHandler(bytes4)": FunctionFragment;
    "getActiveHook()": FunctionFragment;
    "getExecutorsPaginated(address,uint256)": FunctionFragment;
    "getValidatorPaginated(address,uint256)": FunctionFragment;
    "initMSA((address,bytes)[],(address,bytes)[],(address,bytes),(address,bytes)[])": FunctionFragment;
    "singleInitMSA(address,bytes)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "_getInitMSACalldata"
      | "entryPoint"
      | "getActiveFallbackHandler"
      | "getActiveHook"
      | "getExecutorsPaginated"
      | "getValidatorPaginated"
      | "initMSA"
      | "singleInitMSA"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "_getInitMSACalldata",
    values: [
      BootstrapConfigStruct[],
      BootstrapConfigStruct[],
      BootstrapConfigStruct,
      BootstrapConfigStruct[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "entryPoint",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getActiveFallbackHandler",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "getActiveHook",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getExecutorsPaginated",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "getValidatorPaginated",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "initMSA",
    values: [
      BootstrapConfigStruct[],
      BootstrapConfigStruct[],
      BootstrapConfigStruct,
      BootstrapConfigStruct[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "singleInitMSA",
    values: [PromiseOrValue<string>, PromiseOrValue<BytesLike>]
  ): string;

  decodeFunctionResult(
    functionFragment: "_getInitMSACalldata",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "entryPoint", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getActiveFallbackHandler",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getActiveHook",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getExecutorsPaginated",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getValidatorPaginated",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "initMSA", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "singleInitMSA",
    data: BytesLike
  ): Result;

  events: {};
}

export interface Bootstrap extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: BootstrapInterface;

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
    _getInitMSACalldata(
      $valdiators: BootstrapConfigStruct[],
      $executors: BootstrapConfigStruct[],
      _hook: BootstrapConfigStruct,
      _fallbacks: BootstrapConfigStruct[],
      overrides?: CallOverrides
    ): Promise<[string] & { init: string }>;

    entryPoint(overrides?: CallOverrides): Promise<[string]>;

    getActiveFallbackHandler(
      functionSig: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[ModuleManager.FallbackHandlerStructOutput]>;

    getActiveHook(
      overrides?: CallOverrides
    ): Promise<[string] & { hook: string }>;

    getExecutorsPaginated(
      cursor: PromiseOrValue<string>,
      size: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string[], string] & { array: string[]; next: string }>;

    getValidatorPaginated(
      cursor: PromiseOrValue<string>,
      size: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string[], string] & { array: string[]; next: string }>;

    initMSA(
      $valdiators: BootstrapConfigStruct[],
      $executors: BootstrapConfigStruct[],
      _hook: BootstrapConfigStruct,
      _fallbacks: BootstrapConfigStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    singleInitMSA(
      validator: PromiseOrValue<string>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  _getInitMSACalldata(
    $valdiators: BootstrapConfigStruct[],
    $executors: BootstrapConfigStruct[],
    _hook: BootstrapConfigStruct,
    _fallbacks: BootstrapConfigStruct[],
    overrides?: CallOverrides
  ): Promise<string>;

  entryPoint(overrides?: CallOverrides): Promise<string>;

  getActiveFallbackHandler(
    functionSig: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<ModuleManager.FallbackHandlerStructOutput>;

  getActiveHook(overrides?: CallOverrides): Promise<string>;

  getExecutorsPaginated(
    cursor: PromiseOrValue<string>,
    size: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<[string[], string] & { array: string[]; next: string }>;

  getValidatorPaginated(
    cursor: PromiseOrValue<string>,
    size: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<[string[], string] & { array: string[]; next: string }>;

  initMSA(
    $valdiators: BootstrapConfigStruct[],
    $executors: BootstrapConfigStruct[],
    _hook: BootstrapConfigStruct,
    _fallbacks: BootstrapConfigStruct[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  singleInitMSA(
    validator: PromiseOrValue<string>,
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    _getInitMSACalldata(
      $valdiators: BootstrapConfigStruct[],
      $executors: BootstrapConfigStruct[],
      _hook: BootstrapConfigStruct,
      _fallbacks: BootstrapConfigStruct[],
      overrides?: CallOverrides
    ): Promise<string>;

    entryPoint(overrides?: CallOverrides): Promise<string>;

    getActiveFallbackHandler(
      functionSig: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<ModuleManager.FallbackHandlerStructOutput>;

    getActiveHook(overrides?: CallOverrides): Promise<string>;

    getExecutorsPaginated(
      cursor: PromiseOrValue<string>,
      size: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string[], string] & { array: string[]; next: string }>;

    getValidatorPaginated(
      cursor: PromiseOrValue<string>,
      size: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string[], string] & { array: string[]; next: string }>;

    initMSA(
      $valdiators: BootstrapConfigStruct[],
      $executors: BootstrapConfigStruct[],
      _hook: BootstrapConfigStruct,
      _fallbacks: BootstrapConfigStruct[],
      overrides?: CallOverrides
    ): Promise<void>;

    singleInitMSA(
      validator: PromiseOrValue<string>,
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    _getInitMSACalldata(
      $valdiators: BootstrapConfigStruct[],
      $executors: BootstrapConfigStruct[],
      _hook: BootstrapConfigStruct,
      _fallbacks: BootstrapConfigStruct[],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    entryPoint(overrides?: CallOverrides): Promise<BigNumber>;

    getActiveFallbackHandler(
      functionSig: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getActiveHook(overrides?: CallOverrides): Promise<BigNumber>;

    getExecutorsPaginated(
      cursor: PromiseOrValue<string>,
      size: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getValidatorPaginated(
      cursor: PromiseOrValue<string>,
      size: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    initMSA(
      $valdiators: BootstrapConfigStruct[],
      $executors: BootstrapConfigStruct[],
      _hook: BootstrapConfigStruct,
      _fallbacks: BootstrapConfigStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    singleInitMSA(
      validator: PromiseOrValue<string>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    _getInitMSACalldata(
      $valdiators: BootstrapConfigStruct[],
      $executors: BootstrapConfigStruct[],
      _hook: BootstrapConfigStruct,
      _fallbacks: BootstrapConfigStruct[],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    entryPoint(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getActiveFallbackHandler(
      functionSig: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getActiveHook(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getExecutorsPaginated(
      cursor: PromiseOrValue<string>,
      size: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getValidatorPaginated(
      cursor: PromiseOrValue<string>,
      size: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    initMSA(
      $valdiators: BootstrapConfigStruct[],
      $executors: BootstrapConfigStruct[],
      _hook: BootstrapConfigStruct,
      _fallbacks: BootstrapConfigStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    singleInitMSA(
      validator: PromiseOrValue<string>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}