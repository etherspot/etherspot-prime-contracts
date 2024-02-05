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
} from "../../../common";

export type ManifestExecutionFunctionStruct = {
  selector: PromiseOrValue<BytesLike>;
  permissions: PromiseOrValue<string>[];
};

export type ManifestExecutionFunctionStructOutput = [string, string[]] & {
  selector: string;
  permissions: string[];
};

export type ManifestExternalCallPermissionStruct = {
  externalAddress: PromiseOrValue<string>;
  permitAnySelector: PromiseOrValue<boolean>;
  selectors: PromiseOrValue<BytesLike>[];
};

export type ManifestExternalCallPermissionStructOutput = [
  string,
  boolean,
  string[]
] & {
  externalAddress: string;
  permitAnySelector: boolean;
  selectors: string[];
};

export type ManifestFunctionStruct = {
  functionType: PromiseOrValue<BigNumberish>;
  functionId: PromiseOrValue<BigNumberish>;
  dependencyIndex: PromiseOrValue<BigNumberish>;
};

export type ManifestFunctionStructOutput = [number, number, BigNumber] & {
  functionType: number;
  functionId: number;
  dependencyIndex: BigNumber;
};

export type ManifestAssociatedFunctionStruct = {
  executionSelector: PromiseOrValue<BytesLike>;
  associatedFunction: ManifestFunctionStruct;
};

export type ManifestAssociatedFunctionStructOutput = [
  string,
  ManifestFunctionStructOutput
] & {
  executionSelector: string;
  associatedFunction: ManifestFunctionStructOutput;
};

export type ManifestExecutionHookStruct = {
  executionSelector: PromiseOrValue<BytesLike>;
  preExecHook: ManifestFunctionStruct;
  postExecHook: ManifestFunctionStruct;
};

export type ManifestExecutionHookStructOutput = [
  string,
  ManifestFunctionStructOutput,
  ManifestFunctionStructOutput
] & {
  executionSelector: string;
  preExecHook: ManifestFunctionStructOutput;
  postExecHook: ManifestFunctionStructOutput;
};

export type PluginManifestStruct = {
  name: PromiseOrValue<string>;
  version: PromiseOrValue<string>;
  author: PromiseOrValue<string>;
  interfaceIds: PromiseOrValue<BytesLike>[];
  dependencyInterfaceIds: PromiseOrValue<BytesLike>[];
  executionFunctions: ManifestExecutionFunctionStruct[];
  permittedExecutionSelectors: PromiseOrValue<BytesLike>[];
  permitAnyExternalContract: PromiseOrValue<boolean>;
  permittedExternalCalls: ManifestExternalCallPermissionStruct[];
  userOpValidationFunctions: ManifestAssociatedFunctionStruct[];
  runtimeValidationFunctions: ManifestAssociatedFunctionStruct[];
  preUserOpValidationHooks: ManifestAssociatedFunctionStruct[];
  preRuntimeValidationHooks: ManifestAssociatedFunctionStruct[];
  executionHooks: ManifestExecutionHookStruct[];
  permittedCallHooks: ManifestExecutionHookStruct[];
};

export type PluginManifestStructOutput = [
  string,
  string,
  string,
  string[],
  string[],
  ManifestExecutionFunctionStructOutput[],
  string[],
  boolean,
  ManifestExternalCallPermissionStructOutput[],
  ManifestAssociatedFunctionStructOutput[],
  ManifestAssociatedFunctionStructOutput[],
  ManifestAssociatedFunctionStructOutput[],
  ManifestAssociatedFunctionStructOutput[],
  ManifestExecutionHookStructOutput[],
  ManifestExecutionHookStructOutput[]
] & {
  name: string;
  version: string;
  author: string;
  interfaceIds: string[];
  dependencyInterfaceIds: string[];
  executionFunctions: ManifestExecutionFunctionStructOutput[];
  permittedExecutionSelectors: string[];
  permitAnyExternalContract: boolean;
  permittedExternalCalls: ManifestExternalCallPermissionStructOutput[];
  userOpValidationFunctions: ManifestAssociatedFunctionStructOutput[];
  runtimeValidationFunctions: ManifestAssociatedFunctionStructOutput[];
  preUserOpValidationHooks: ManifestAssociatedFunctionStructOutput[];
  preRuntimeValidationHooks: ManifestAssociatedFunctionStructOutput[];
  executionHooks: ManifestExecutionHookStructOutput[];
  permittedCallHooks: ManifestExecutionHookStructOutput[];
};

export type UserOperationStruct = {
  sender: PromiseOrValue<string>;
  nonce: PromiseOrValue<BigNumberish>;
  initCode: PromiseOrValue<BytesLike>;
  callData: PromiseOrValue<BytesLike>;
  callGasLimit: PromiseOrValue<BigNumberish>;
  verificationGasLimit: PromiseOrValue<BigNumberish>;
  preVerificationGas: PromiseOrValue<BigNumberish>;
  maxFeePerGas: PromiseOrValue<BigNumberish>;
  maxPriorityFeePerGas: PromiseOrValue<BigNumberish>;
  paymasterAndData: PromiseOrValue<BytesLike>;
  signature: PromiseOrValue<BytesLike>;
};

export type UserOperationStructOutput = [
  string,
  BigNumber,
  string,
  string,
  BigNumber,
  BigNumber,
  BigNumber,
  BigNumber,
  BigNumber,
  string,
  string
] & {
  sender: string;
  nonce: BigNumber;
  initCode: string;
  callData: string;
  callGasLimit: BigNumber;
  verificationGasLimit: BigNumber;
  preVerificationGas: BigNumber;
  maxFeePerGas: BigNumber;
  maxPriorityFeePerGas: BigNumber;
  paymasterAndData: string;
  signature: string;
};

export declare namespace IPluginManager {
  export type InjectedHooksInfoStruct = {
    preExecHookFunctionId: PromiseOrValue<BigNumberish>;
    isPostHookUsed: PromiseOrValue<boolean>;
    postExecHookFunctionId: PromiseOrValue<BigNumberish>;
  };

  export type InjectedHooksInfoStructOutput = [number, boolean, number] & {
    preExecHookFunctionId: number;
    isPostHookUsed: boolean;
    postExecHookFunctionId: number;
  };
}

export interface BasePluginInterface extends utils.Interface {
  functions: {
    "onHookApply(address,(uint8,bool,uint8),bytes)": FunctionFragment;
    "onHookUnapply(address,(uint8,bool,uint8),bytes)": FunctionFragment;
    "onInstall(bytes)": FunctionFragment;
    "onUninstall(bytes)": FunctionFragment;
    "pluginManifest()": FunctionFragment;
    "postExecutionHook(uint8,bytes)": FunctionFragment;
    "preExecutionHook(uint8,address,uint256,bytes)": FunctionFragment;
    "preRuntimeValidationHook(uint8,address,uint256,bytes)": FunctionFragment;
    "preUserOpValidationHook(uint8,(address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes),bytes32)": FunctionFragment;
    "runtimeValidationFunction(uint8,address,uint256,bytes)": FunctionFragment;
    "supportsInterface(bytes4)": FunctionFragment;
    "userOpValidationFunction(uint8,(address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes),bytes32)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "onHookApply"
      | "onHookUnapply"
      | "onInstall"
      | "onUninstall"
      | "pluginManifest"
      | "postExecutionHook"
      | "preExecutionHook"
      | "preRuntimeValidationHook"
      | "preUserOpValidationHook"
      | "runtimeValidationFunction"
      | "supportsInterface"
      | "userOpValidationFunction"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "onHookApply",
    values: [
      PromiseOrValue<string>,
      IPluginManager.InjectedHooksInfoStruct,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "onHookUnapply",
    values: [
      PromiseOrValue<string>,
      IPluginManager.InjectedHooksInfoStruct,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "onInstall",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "onUninstall",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "pluginManifest",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "postExecutionHook",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "preExecutionHook",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "preRuntimeValidationHook",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "preUserOpValidationHook",
    values: [
      PromiseOrValue<BigNumberish>,
      UserOperationStruct,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "runtimeValidationFunction",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "supportsInterface",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "userOpValidationFunction",
    values: [
      PromiseOrValue<BigNumberish>,
      UserOperationStruct,
      PromiseOrValue<BytesLike>
    ]
  ): string;

  decodeFunctionResult(
    functionFragment: "onHookApply",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "onHookUnapply",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "onInstall", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "onUninstall",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "pluginManifest",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "postExecutionHook",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "preExecutionHook",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "preRuntimeValidationHook",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "preUserOpValidationHook",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "runtimeValidationFunction",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "supportsInterface",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "userOpValidationFunction",
    data: BytesLike
  ): Result;

  events: {};
}

export interface BasePlugin extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: BasePluginInterface;

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
    onHookApply(
      pluginAppliedOn: PromiseOrValue<string>,
      injectedHooksInfo: IPluginManager.InjectedHooksInfoStruct,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    onHookUnapply(
      pluginAppliedOn: PromiseOrValue<string>,
      injectedHooksInfo: IPluginManager.InjectedHooksInfoStruct,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    onInstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    onUninstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    pluginManifest(
      overrides?: CallOverrides
    ): Promise<[PluginManifestStructOutput]>;

    postExecutionHook(
      functionId: PromiseOrValue<BigNumberish>,
      preExecHookData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    preExecutionHook(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    preRuntimeValidationHook(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    preUserOpValidationHook(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    runtimeValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    userOpValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  onHookApply(
    pluginAppliedOn: PromiseOrValue<string>,
    injectedHooksInfo: IPluginManager.InjectedHooksInfoStruct,
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  onHookUnapply(
    pluginAppliedOn: PromiseOrValue<string>,
    injectedHooksInfo: IPluginManager.InjectedHooksInfoStruct,
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  onInstall(
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  onUninstall(
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  pluginManifest(
    overrides?: CallOverrides
  ): Promise<PluginManifestStructOutput>;

  postExecutionHook(
    functionId: PromiseOrValue<BigNumberish>,
    preExecHookData: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  preExecutionHook(
    functionId: PromiseOrValue<BigNumberish>,
    sender: PromiseOrValue<string>,
    value: PromiseOrValue<BigNumberish>,
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  preRuntimeValidationHook(
    functionId: PromiseOrValue<BigNumberish>,
    sender: PromiseOrValue<string>,
    value: PromiseOrValue<BigNumberish>,
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  preUserOpValidationHook(
    functionId: PromiseOrValue<BigNumberish>,
    userOp: UserOperationStruct,
    userOpHash: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  runtimeValidationFunction(
    functionId: PromiseOrValue<BigNumberish>,
    sender: PromiseOrValue<string>,
    value: PromiseOrValue<BigNumberish>,
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  supportsInterface(
    interfaceId: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  userOpValidationFunction(
    functionId: PromiseOrValue<BigNumberish>,
    userOp: UserOperationStruct,
    userOpHash: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    onHookApply(
      pluginAppliedOn: PromiseOrValue<string>,
      injectedHooksInfo: IPluginManager.InjectedHooksInfoStruct,
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    onHookUnapply(
      pluginAppliedOn: PromiseOrValue<string>,
      injectedHooksInfo: IPluginManager.InjectedHooksInfoStruct,
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    onInstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    onUninstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    pluginManifest(
      overrides?: CallOverrides
    ): Promise<PluginManifestStructOutput>;

    postExecutionHook(
      functionId: PromiseOrValue<BigNumberish>,
      preExecHookData: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    preExecutionHook(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string>;

    preRuntimeValidationHook(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    preUserOpValidationHook(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    runtimeValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    userOpValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  filters: {};

  estimateGas: {
    onHookApply(
      pluginAppliedOn: PromiseOrValue<string>,
      injectedHooksInfo: IPluginManager.InjectedHooksInfoStruct,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    onHookUnapply(
      pluginAppliedOn: PromiseOrValue<string>,
      injectedHooksInfo: IPluginManager.InjectedHooksInfoStruct,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    onInstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    onUninstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    pluginManifest(overrides?: CallOverrides): Promise<BigNumber>;

    postExecutionHook(
      functionId: PromiseOrValue<BigNumberish>,
      preExecHookData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    preExecutionHook(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    preRuntimeValidationHook(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    preUserOpValidationHook(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    runtimeValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    userOpValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    onHookApply(
      pluginAppliedOn: PromiseOrValue<string>,
      injectedHooksInfo: IPluginManager.InjectedHooksInfoStruct,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    onHookUnapply(
      pluginAppliedOn: PromiseOrValue<string>,
      injectedHooksInfo: IPluginManager.InjectedHooksInfoStruct,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    onInstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    onUninstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    pluginManifest(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    postExecutionHook(
      functionId: PromiseOrValue<BigNumberish>,
      preExecHookData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    preExecutionHook(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    preRuntimeValidationHook(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    preUserOpValidationHook(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    runtimeValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    userOpValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
