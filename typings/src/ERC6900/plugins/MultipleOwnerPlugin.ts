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

export interface MultipleOwnerPluginInterface extends utils.Interface {
  functions: {
    "AUTHOR()": FunctionFragment;
    "NAME()": FunctionFragment;
    "VERSION()": FunctionFragment;
    "addOwner(address,address)": FunctionFragment;
    "isOwner(address)": FunctionFragment;
    "isOwnerOfAccount(address,address)": FunctionFragment;
    "isValidSig(address,bytes32,bytes)": FunctionFragment;
    "onHookApply(address,(uint8,bool,uint8),bytes)": FunctionFragment;
    "onHookUnapply(address,(uint8,bool,uint8),bytes)": FunctionFragment;
    "onInstall(bytes)": FunctionFragment;
    "onUninstall(bytes)": FunctionFragment;
    "owners()": FunctionFragment;
    "ownersOf(address)": FunctionFragment;
    "pluginManifest()": FunctionFragment;
    "postExecutionHook(uint8,bytes)": FunctionFragment;
    "preExecutionHook(uint8,address,uint256,bytes)": FunctionFragment;
    "preRuntimeValidationHook(uint8,address,uint256,bytes)": FunctionFragment;
    "preUserOpValidationHook(uint8,(address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes),bytes32)": FunctionFragment;
    "removeOwner(address,address)": FunctionFragment;
    "runtimeValidationFunction(uint8,address,uint256,bytes)": FunctionFragment;
    "supportsInterface(bytes4)": FunctionFragment;
    "transferOwnership(address)": FunctionFragment;
    "userOpValidationFunction(uint8,(address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes),bytes32)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "AUTHOR"
      | "NAME"
      | "VERSION"
      | "addOwner"
      | "isOwner"
      | "isOwnerOfAccount"
      | "isValidSig"
      | "onHookApply"
      | "onHookUnapply"
      | "onInstall"
      | "onUninstall"
      | "owners"
      | "ownersOf"
      | "pluginManifest"
      | "postExecutionHook"
      | "preExecutionHook"
      | "preRuntimeValidationHook"
      | "preUserOpValidationHook"
      | "removeOwner"
      | "runtimeValidationFunction"
      | "supportsInterface"
      | "transferOwnership"
      | "userOpValidationFunction"
  ): FunctionFragment;

  encodeFunctionData(functionFragment: "AUTHOR", values?: undefined): string;
  encodeFunctionData(functionFragment: "NAME", values?: undefined): string;
  encodeFunctionData(functionFragment: "VERSION", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "addOwner",
    values: [PromiseOrValue<string>, PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "isOwner",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "isOwnerOfAccount",
    values: [PromiseOrValue<string>, PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "isValidSig",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BytesLike>,
      PromiseOrValue<BytesLike>
    ]
  ): string;
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
  encodeFunctionData(functionFragment: "owners", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "ownersOf",
    values: [PromiseOrValue<string>]
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
    functionFragment: "removeOwner",
    values: [PromiseOrValue<string>, PromiseOrValue<string>]
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
    functionFragment: "transferOwnership",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "userOpValidationFunction",
    values: [
      PromiseOrValue<BigNumberish>,
      UserOperationStruct,
      PromiseOrValue<BytesLike>
    ]
  ): string;

  decodeFunctionResult(functionFragment: "AUTHOR", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "NAME", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "VERSION", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "addOwner", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "isOwner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "isOwnerOfAccount",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "isValidSig", data: BytesLike): Result;
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
  decodeFunctionResult(functionFragment: "owners", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "ownersOf", data: BytesLike): Result;
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
    functionFragment: "removeOwner",
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
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "userOpValidationFunction",
    data: BytesLike
  ): Result;

  events: {
    "OwnerAdded(address,address)": EventFragment;
    "OwnerRemoved(address,address)": EventFragment;
    "OwnershipTransferred(address,address,address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "OwnerAdded"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnerRemoved"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
}

export interface OwnerAddedEventObject {
  account: string;
  added: string;
}
export type OwnerAddedEvent = TypedEvent<
  [string, string],
  OwnerAddedEventObject
>;

export type OwnerAddedEventFilter = TypedEventFilter<OwnerAddedEvent>;

export interface OwnerRemovedEventObject {
  account: string;
  removed: string;
}
export type OwnerRemovedEvent = TypedEvent<
  [string, string],
  OwnerRemovedEventObject
>;

export type OwnerRemovedEventFilter = TypedEventFilter<OwnerRemovedEvent>;

export interface OwnershipTransferredEventObject {
  account: string;
  previousOwner: string;
  newOwner: string;
}
export type OwnershipTransferredEvent = TypedEvent<
  [string, string, string],
  OwnershipTransferredEventObject
>;

export type OwnershipTransferredEventFilter =
  TypedEventFilter<OwnershipTransferredEvent>;

export interface MultipleOwnerPlugin extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: MultipleOwnerPluginInterface;

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
    AUTHOR(overrides?: CallOverrides): Promise<[string]>;

    NAME(overrides?: CallOverrides): Promise<[string]>;

    VERSION(overrides?: CallOverrides): Promise<[string]>;

    addOwner(
      _account: PromiseOrValue<string>,
      _newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    isOwner(
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isOwnerOfAccount(
      _account: PromiseOrValue<string>,
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isValidSig(
      _signer: PromiseOrValue<string>,
      _digest: PromiseOrValue<BytesLike>,
      _signature: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[string]>;

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
      arg0: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    owners(overrides?: CallOverrides): Promise<[string[]]>;

    ownersOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[string[]]>;

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

    removeOwner(
      _account: PromiseOrValue<string>,
      _owner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    runtimeValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      arg2: PromiseOrValue<BigNumberish>,
      arg3: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[void]>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    userOpValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;
  };

  AUTHOR(overrides?: CallOverrides): Promise<string>;

  NAME(overrides?: CallOverrides): Promise<string>;

  VERSION(overrides?: CallOverrides): Promise<string>;

  addOwner(
    _account: PromiseOrValue<string>,
    _newOwner: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  isOwner(
    _owner: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isOwnerOfAccount(
    _account: PromiseOrValue<string>,
    _owner: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isValidSig(
    _signer: PromiseOrValue<string>,
    _digest: PromiseOrValue<BytesLike>,
    _signature: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<string>;

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
    arg0: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  owners(overrides?: CallOverrides): Promise<string[]>;

  ownersOf(
    _account: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<string[]>;

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

  removeOwner(
    _account: PromiseOrValue<string>,
    _owner: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  runtimeValidationFunction(
    functionId: PromiseOrValue<BigNumberish>,
    sender: PromiseOrValue<string>,
    arg2: PromiseOrValue<BigNumberish>,
    arg3: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<void>;

  supportsInterface(
    interfaceId: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  transferOwnership(
    newOwner: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  userOpValidationFunction(
    functionId: PromiseOrValue<BigNumberish>,
    userOp: UserOperationStruct,
    userOpHash: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  callStatic: {
    AUTHOR(overrides?: CallOverrides): Promise<string>;

    NAME(overrides?: CallOverrides): Promise<string>;

    VERSION(overrides?: CallOverrides): Promise<string>;

    addOwner(
      _account: PromiseOrValue<string>,
      _newOwner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    isOwner(
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isOwnerOfAccount(
      _account: PromiseOrValue<string>,
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isValidSig(
      _signer: PromiseOrValue<string>,
      _digest: PromiseOrValue<BytesLike>,
      _signature: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string>;

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
      arg0: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    owners(overrides?: CallOverrides): Promise<string[]>;

    ownersOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<string[]>;

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

    removeOwner(
      _account: PromiseOrValue<string>,
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    runtimeValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      arg2: PromiseOrValue<BigNumberish>,
      arg3: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    userOpValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  filters: {
    "OwnerAdded(address,address)"(
      account?: null,
      added?: null
    ): OwnerAddedEventFilter;
    OwnerAdded(account?: null, added?: null): OwnerAddedEventFilter;

    "OwnerRemoved(address,address)"(
      account?: null,
      removed?: null
    ): OwnerRemovedEventFilter;
    OwnerRemoved(account?: null, removed?: null): OwnerRemovedEventFilter;

    "OwnershipTransferred(address,address,address)"(
      account?: PromiseOrValue<string> | null,
      previousOwner?: PromiseOrValue<string> | null,
      newOwner?: PromiseOrValue<string> | null
    ): OwnershipTransferredEventFilter;
    OwnershipTransferred(
      account?: PromiseOrValue<string> | null,
      previousOwner?: PromiseOrValue<string> | null,
      newOwner?: PromiseOrValue<string> | null
    ): OwnershipTransferredEventFilter;
  };

  estimateGas: {
    AUTHOR(overrides?: CallOverrides): Promise<BigNumber>;

    NAME(overrides?: CallOverrides): Promise<BigNumber>;

    VERSION(overrides?: CallOverrides): Promise<BigNumber>;

    addOwner(
      _account: PromiseOrValue<string>,
      _newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    isOwner(
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isOwnerOfAccount(
      _account: PromiseOrValue<string>,
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isValidSig(
      _signer: PromiseOrValue<string>,
      _digest: PromiseOrValue<BytesLike>,
      _signature: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

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
      arg0: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    owners(overrides?: CallOverrides): Promise<BigNumber>;

    ownersOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
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

    removeOwner(
      _account: PromiseOrValue<string>,
      _owner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    runtimeValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      arg2: PromiseOrValue<BigNumberish>,
      arg3: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    userOpValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    AUTHOR(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    NAME(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    VERSION(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    addOwner(
      _account: PromiseOrValue<string>,
      _newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    isOwner(
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isOwnerOfAccount(
      _account: PromiseOrValue<string>,
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isValidSig(
      _signer: PromiseOrValue<string>,
      _digest: PromiseOrValue<BytesLike>,
      _signature: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

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
      arg0: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    owners(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    ownersOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
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

    removeOwner(
      _account: PromiseOrValue<string>,
      _owner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    runtimeValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      sender: PromiseOrValue<string>,
      arg2: PromiseOrValue<BigNumberish>,
      arg3: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    userOpValidationFunction(
      functionId: PromiseOrValue<BigNumberish>,
      userOp: UserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
