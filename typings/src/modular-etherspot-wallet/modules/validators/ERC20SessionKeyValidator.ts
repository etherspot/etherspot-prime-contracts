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
} from 'ethers';
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from '@ethersproject/abi';
import type { Listener, Provider } from '@ethersproject/providers';
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from '../../../../common';

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

export declare namespace IERC20SessionKeyValidator {
  export type SessionDataStruct = {
    token: PromiseOrValue<string>;
    funcSelector: PromiseOrValue<BytesLike>;
    spendingLimit: PromiseOrValue<BigNumberish>;
    validAfter: PromiseOrValue<BigNumberish>;
    validUntil: PromiseOrValue<BigNumberish>;
    live: PromiseOrValue<boolean>;
  };

  export type SessionDataStructOutput = [
    string,
    string,
    BigNumber,
    number,
    number,
    boolean
  ] & {
    token: string;
    funcSelector: string;
    spendingLimit: BigNumber;
    validAfter: number;
    validUntil: number;
    live: boolean;
  };
}

export interface ERC20SessionKeyValidatorInterface extends utils.Interface {
  functions: {
    'disableSessionKey(address)': FunctionFragment;
    'enableSessionKey(bytes)': FunctionFragment;
    'getAssociatedSessionKeys()': FunctionFragment;
    'getSessionKeyData(address)': FunctionFragment;
    'initialized(address)': FunctionFragment;
    'isInitialized(address)': FunctionFragment;
    'isModuleType(uint256)': FunctionFragment;
    'isSessionKeyLive(address)': FunctionFragment;
    'isValidSignatureWithSender(address,bytes32,bytes)': FunctionFragment;
    'onInstall(bytes)': FunctionFragment;
    'onUninstall(bytes)': FunctionFragment;
    'rotateSessionKey(address,bytes)': FunctionFragment;
    'sessionData(address,address)': FunctionFragment;
    'toggleSessionKeyPause(address)': FunctionFragment;
    'validateSessionKeyParams(address,(address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes))': FunctionFragment;
    'validateUserOp((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes),bytes32)': FunctionFragment;
    'walletSessionKeys(address,uint256)': FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | 'disableSessionKey'
      | 'enableSessionKey'
      | 'getAssociatedSessionKeys'
      | 'getSessionKeyData'
      | 'initialized'
      | 'isInitialized'
      | 'isModuleType'
      | 'isSessionKeyLive'
      | 'isValidSignatureWithSender'
      | 'onInstall'
      | 'onUninstall'
      | 'rotateSessionKey'
      | 'sessionData'
      | 'toggleSessionKeyPause'
      | 'validateSessionKeyParams'
      | 'validateUserOp'
      | 'walletSessionKeys'
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: 'disableSessionKey',
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: 'enableSessionKey',
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: 'getAssociatedSessionKeys',
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: 'getSessionKeyData',
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: 'initialized',
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: 'isInitialized',
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: 'isModuleType',
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: 'isSessionKeyLive',
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: 'isValidSignatureWithSender',
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BytesLike>,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: 'onInstall',
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: 'onUninstall',
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: 'rotateSessionKey',
    values: [PromiseOrValue<string>, PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: 'sessionData',
    values: [PromiseOrValue<string>, PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: 'toggleSessionKeyPause',
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: 'validateSessionKeyParams',
    values: [PromiseOrValue<string>, PackedUserOperationStruct]
  ): string;
  encodeFunctionData(
    functionFragment: 'validateUserOp',
    values: [PackedUserOperationStruct, PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: 'walletSessionKeys',
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;

  decodeFunctionResult(
    functionFragment: 'disableSessionKey',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'enableSessionKey',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'getAssociatedSessionKeys',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'getSessionKeyData',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'initialized',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'isInitialized',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'isModuleType',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'isSessionKeyLive',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'isValidSignatureWithSender',
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: 'onInstall', data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: 'onUninstall',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'rotateSessionKey',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'sessionData',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'toggleSessionKeyPause',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'validateSessionKeyParams',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'validateUserOp',
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: 'walletSessionKeys',
    data: BytesLike
  ): Result;

  events: {
    'ERC20SKV_ModuleInstalled(address)': EventFragment;
    'ERC20SKV_ModuleUninstalled(address)': EventFragment;
    'ERC20SKV_NotUsingExecuteFunction(bytes4)': EventFragment;
    'ERC20SKV_SelectorError(bytes4,bytes4)': EventFragment;
    'ERC20SKV_SessionKeyDisabled(address,address)': EventFragment;
    'ERC20SKV_SessionKeyEnabled(address,address)': EventFragment;
    'ERC20SKV_SessionKeyIsNotLive(address)': EventFragment;
    'ERC20SKV_SessionKeyPaused(address,address)': EventFragment;
    'ERC20SKV_SessionKeyUnpaused(address,address)': EventFragment;
    'ERC20SKV_SpendingLimitError(uint256,uint256)': EventFragment;
    'ERC20SKV_TokenError(address,address)': EventFragment;
    'ERC20SKV_UnsupportedCallType(bytes1)': EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: 'ERC20SKV_ModuleInstalled'): EventFragment;
  getEvent(nameOrSignatureOrTopic: 'ERC20SKV_ModuleUninstalled'): EventFragment;
  getEvent(
    nameOrSignatureOrTopic: 'ERC20SKV_NotUsingExecuteFunction'
  ): EventFragment;
  getEvent(nameOrSignatureOrTopic: 'ERC20SKV_SelectorError'): EventFragment;
  getEvent(
    nameOrSignatureOrTopic: 'ERC20SKV_SessionKeyDisabled'
  ): EventFragment;
  getEvent(nameOrSignatureOrTopic: 'ERC20SKV_SessionKeyEnabled'): EventFragment;
  getEvent(
    nameOrSignatureOrTopic: 'ERC20SKV_SessionKeyIsNotLive'
  ): EventFragment;
  getEvent(nameOrSignatureOrTopic: 'ERC20SKV_SessionKeyPaused'): EventFragment;
  getEvent(
    nameOrSignatureOrTopic: 'ERC20SKV_SessionKeyUnpaused'
  ): EventFragment;
  getEvent(
    nameOrSignatureOrTopic: 'ERC20SKV_SpendingLimitError'
  ): EventFragment;
  getEvent(nameOrSignatureOrTopic: 'ERC20SKV_TokenError'): EventFragment;
  getEvent(
    nameOrSignatureOrTopic: 'ERC20SKV_UnsupportedCallType'
  ): EventFragment;
}

export interface ERC20SKV_ModuleInstalledEventObject {
  wallet: string;
}
export type ERC20SKV_ModuleInstalledEvent = TypedEvent<
  [string],
  ERC20SKV_ModuleInstalledEventObject
>;

export type ERC20SKV_ModuleInstalledEventFilter =
  TypedEventFilter<ERC20SKV_ModuleInstalledEvent>;

export interface ERC20SKV_ModuleUninstalledEventObject {
  wallet: string;
}
export type ERC20SKV_ModuleUninstalledEvent = TypedEvent<
  [string],
  ERC20SKV_ModuleUninstalledEventObject
>;

export type ERC20SKV_ModuleUninstalledEventFilter =
  TypedEventFilter<ERC20SKV_ModuleUninstalledEvent>;

export interface ERC20SKV_NotUsingExecuteFunctionEventObject {
  sel: string;
}
export type ERC20SKV_NotUsingExecuteFunctionEvent = TypedEvent<
  [string],
  ERC20SKV_NotUsingExecuteFunctionEventObject
>;

export type ERC20SKV_NotUsingExecuteFunctionEventFilter =
  TypedEventFilter<ERC20SKV_NotUsingExecuteFunctionEvent>;

export interface ERC20SKV_SelectorErrorEventObject {
  selector: string;
  sessionSelector: string;
}
export type ERC20SKV_SelectorErrorEvent = TypedEvent<
  [string, string],
  ERC20SKV_SelectorErrorEventObject
>;

export type ERC20SKV_SelectorErrorEventFilter =
  TypedEventFilter<ERC20SKV_SelectorErrorEvent>;

export interface ERC20SKV_SessionKeyDisabledEventObject {
  sessionKey: string;
  wallet: string;
}
export type ERC20SKV_SessionKeyDisabledEvent = TypedEvent<
  [string, string],
  ERC20SKV_SessionKeyDisabledEventObject
>;

export type ERC20SKV_SessionKeyDisabledEventFilter =
  TypedEventFilter<ERC20SKV_SessionKeyDisabledEvent>;

export interface ERC20SKV_SessionKeyEnabledEventObject {
  sessionKey: string;
  wallet: string;
}
export type ERC20SKV_SessionKeyEnabledEvent = TypedEvent<
  [string, string],
  ERC20SKV_SessionKeyEnabledEventObject
>;

export type ERC20SKV_SessionKeyEnabledEventFilter =
  TypedEventFilter<ERC20SKV_SessionKeyEnabledEvent>;

export interface ERC20SKV_SessionKeyIsNotLiveEventObject {
  _sessionKey: string;
}
export type ERC20SKV_SessionKeyIsNotLiveEvent = TypedEvent<
  [string],
  ERC20SKV_SessionKeyIsNotLiveEventObject
>;

export type ERC20SKV_SessionKeyIsNotLiveEventFilter =
  TypedEventFilter<ERC20SKV_SessionKeyIsNotLiveEvent>;

export interface ERC20SKV_SessionKeyPausedEventObject {
  sessionKey: string;
  wallet: string;
}
export type ERC20SKV_SessionKeyPausedEvent = TypedEvent<
  [string, string],
  ERC20SKV_SessionKeyPausedEventObject
>;

export type ERC20SKV_SessionKeyPausedEventFilter =
  TypedEventFilter<ERC20SKV_SessionKeyPausedEvent>;

export interface ERC20SKV_SessionKeyUnpausedEventObject {
  sessionKey: string;
  wallet: string;
}
export type ERC20SKV_SessionKeyUnpausedEvent = TypedEvent<
  [string, string],
  ERC20SKV_SessionKeyUnpausedEventObject
>;

export type ERC20SKV_SessionKeyUnpausedEventFilter =
  TypedEventFilter<ERC20SKV_SessionKeyUnpausedEvent>;

export interface ERC20SKV_SpendingLimitErrorEventObject {
  amount: BigNumber;
  sessionSpendingLimit: BigNumber;
}
export type ERC20SKV_SpendingLimitErrorEvent = TypedEvent<
  [BigNumber, BigNumber],
  ERC20SKV_SpendingLimitErrorEventObject
>;

export type ERC20SKV_SpendingLimitErrorEventFilter =
  TypedEventFilter<ERC20SKV_SpendingLimitErrorEvent>;

export interface ERC20SKV_TokenErrorEventObject {
  target: string;
  sessionToken: string;
}
export type ERC20SKV_TokenErrorEvent = TypedEvent<
  [string, string],
  ERC20SKV_TokenErrorEventObject
>;

export type ERC20SKV_TokenErrorEventFilter =
  TypedEventFilter<ERC20SKV_TokenErrorEvent>;

export interface ERC20SKV_UnsupportedCallTypeEventObject {
  calltype: string;
}
export type ERC20SKV_UnsupportedCallTypeEvent = TypedEvent<
  [string],
  ERC20SKV_UnsupportedCallTypeEventObject
>;

export type ERC20SKV_UnsupportedCallTypeEventFilter =
  TypedEventFilter<ERC20SKV_UnsupportedCallTypeEvent>;

export interface ERC20SessionKeyValidator extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: ERC20SessionKeyValidatorInterface;

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
    disableSessionKey(
      _session: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    enableSessionKey(
      _sessionData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    getAssociatedSessionKeys(overrides?: CallOverrides): Promise<[string[]]>;

    getSessionKeyData(
      _sessionKey: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[IERC20SessionKeyValidator.SessionDataStructOutput]>;

    initialized(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isModuleType(
      moduleTypeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isSessionKeyLive(
      _sessionKey: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isValidSignatureWithSender(
      sender: PromiseOrValue<string>,
      hash: PromiseOrValue<BytesLike>,
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    onInstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    onUninstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    rotateSessionKey(
      _oldSessionKey: PromiseOrValue<string>,
      _newSessionData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    sessionData(
      sessionKey: PromiseOrValue<string>,
      wallet: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<
      [string, string, BigNumber, number, number, boolean] & {
        token: string;
        funcSelector: string;
        spendingLimit: BigNumber;
        validAfter: number;
        validUntil: number;
        live: boolean;
      }
    >;

    toggleSessionKeyPause(
      _sessionKey: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    validateSessionKeyParams(
      _sessionKey: PromiseOrValue<string>,
      userOp: PackedUserOperationStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    validateUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    walletSessionKeys(
      wallet: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string] & { assocSessionKeys: string }>;
  };

  disableSessionKey(
    _session: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  enableSessionKey(
    _sessionData: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  getAssociatedSessionKeys(overrides?: CallOverrides): Promise<string[]>;

  getSessionKeyData(
    _sessionKey: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<IERC20SessionKeyValidator.SessionDataStructOutput>;

  initialized(
    arg0: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isInitialized(
    smartAccount: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isModuleType(
    moduleTypeId: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isSessionKeyLive(
    _sessionKey: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isValidSignatureWithSender(
    sender: PromiseOrValue<string>,
    hash: PromiseOrValue<BytesLike>,
    data: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<string>;

  onInstall(
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  onUninstall(
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  rotateSessionKey(
    _oldSessionKey: PromiseOrValue<string>,
    _newSessionData: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  sessionData(
    sessionKey: PromiseOrValue<string>,
    wallet: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<
    [string, string, BigNumber, number, number, boolean] & {
      token: string;
      funcSelector: string;
      spendingLimit: BigNumber;
      validAfter: number;
      validUntil: number;
      live: boolean;
    }
  >;

  toggleSessionKeyPause(
    _sessionKey: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  validateSessionKeyParams(
    _sessionKey: PromiseOrValue<string>,
    userOp: PackedUserOperationStruct,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  validateUserOp(
    userOp: PackedUserOperationStruct,
    userOpHash: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  walletSessionKeys(
    wallet: PromiseOrValue<string>,
    arg1: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  callStatic: {
    disableSessionKey(
      _session: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    enableSessionKey(
      _sessionData: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    getAssociatedSessionKeys(overrides?: CallOverrides): Promise<string[]>;

    getSessionKeyData(
      _sessionKey: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<IERC20SessionKeyValidator.SessionDataStructOutput>;

    initialized(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isModuleType(
      moduleTypeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isSessionKeyLive(
      _sessionKey: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isValidSignatureWithSender(
      sender: PromiseOrValue<string>,
      hash: PromiseOrValue<BytesLike>,
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string>;

    onInstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    onUninstall(
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    rotateSessionKey(
      _oldSessionKey: PromiseOrValue<string>,
      _newSessionData: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    sessionData(
      sessionKey: PromiseOrValue<string>,
      wallet: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<
      [string, string, BigNumber, number, number, boolean] & {
        token: string;
        funcSelector: string;
        spendingLimit: BigNumber;
        validAfter: number;
        validUntil: number;
        live: boolean;
      }
    >;

    toggleSessionKeyPause(
      _sessionKey: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    validateSessionKeyParams(
      _sessionKey: PromiseOrValue<string>,
      userOp: PackedUserOperationStruct,
      overrides?: CallOverrides
    ): Promise<boolean>;

    validateUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    walletSessionKeys(
      wallet: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;
  };

  filters: {
    'ERC20SKV_ModuleInstalled(address)'(
      wallet?: null
    ): ERC20SKV_ModuleInstalledEventFilter;
    ERC20SKV_ModuleInstalled(
      wallet?: null
    ): ERC20SKV_ModuleInstalledEventFilter;

    'ERC20SKV_ModuleUninstalled(address)'(
      wallet?: null
    ): ERC20SKV_ModuleUninstalledEventFilter;
    ERC20SKV_ModuleUninstalled(
      wallet?: null
    ): ERC20SKV_ModuleUninstalledEventFilter;

    'ERC20SKV_NotUsingExecuteFunction(bytes4)'(
      sel?: null
    ): ERC20SKV_NotUsingExecuteFunctionEventFilter;
    ERC20SKV_NotUsingExecuteFunction(
      sel?: null
    ): ERC20SKV_NotUsingExecuteFunctionEventFilter;

    'ERC20SKV_SelectorError(bytes4,bytes4)'(
      selector?: null,
      sessionSelector?: null
    ): ERC20SKV_SelectorErrorEventFilter;
    ERC20SKV_SelectorError(
      selector?: null,
      sessionSelector?: null
    ): ERC20SKV_SelectorErrorEventFilter;

    'ERC20SKV_SessionKeyDisabled(address,address)'(
      sessionKey?: null,
      wallet?: null
    ): ERC20SKV_SessionKeyDisabledEventFilter;
    ERC20SKV_SessionKeyDisabled(
      sessionKey?: null,
      wallet?: null
    ): ERC20SKV_SessionKeyDisabledEventFilter;

    'ERC20SKV_SessionKeyEnabled(address,address)'(
      sessionKey?: null,
      wallet?: null
    ): ERC20SKV_SessionKeyEnabledEventFilter;
    ERC20SKV_SessionKeyEnabled(
      sessionKey?: null,
      wallet?: null
    ): ERC20SKV_SessionKeyEnabledEventFilter;

    'ERC20SKV_SessionKeyIsNotLive(address)'(
      _sessionKey?: null
    ): ERC20SKV_SessionKeyIsNotLiveEventFilter;
    ERC20SKV_SessionKeyIsNotLive(
      _sessionKey?: null
    ): ERC20SKV_SessionKeyIsNotLiveEventFilter;

    'ERC20SKV_SessionKeyPaused(address,address)'(
      sessionKey?: null,
      wallet?: null
    ): ERC20SKV_SessionKeyPausedEventFilter;
    ERC20SKV_SessionKeyPaused(
      sessionKey?: null,
      wallet?: null
    ): ERC20SKV_SessionKeyPausedEventFilter;

    'ERC20SKV_SessionKeyUnpaused(address,address)'(
      sessionKey?: null,
      wallet?: null
    ): ERC20SKV_SessionKeyUnpausedEventFilter;
    ERC20SKV_SessionKeyUnpaused(
      sessionKey?: null,
      wallet?: null
    ): ERC20SKV_SessionKeyUnpausedEventFilter;

    'ERC20SKV_SpendingLimitError(uint256,uint256)'(
      amount?: null,
      sessionSpendingLimit?: null
    ): ERC20SKV_SpendingLimitErrorEventFilter;
    ERC20SKV_SpendingLimitError(
      amount?: null,
      sessionSpendingLimit?: null
    ): ERC20SKV_SpendingLimitErrorEventFilter;

    'ERC20SKV_TokenError(address,address)'(
      target?: null,
      sessionToken?: null
    ): ERC20SKV_TokenErrorEventFilter;
    ERC20SKV_TokenError(
      target?: null,
      sessionToken?: null
    ): ERC20SKV_TokenErrorEventFilter;

    'ERC20SKV_UnsupportedCallType(bytes1)'(
      calltype?: null
    ): ERC20SKV_UnsupportedCallTypeEventFilter;
    ERC20SKV_UnsupportedCallType(
      calltype?: null
    ): ERC20SKV_UnsupportedCallTypeEventFilter;
  };

  estimateGas: {
    disableSessionKey(
      _session: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    enableSessionKey(
      _sessionData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    getAssociatedSessionKeys(overrides?: CallOverrides): Promise<BigNumber>;

    getSessionKeyData(
      _sessionKey: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    initialized(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isModuleType(
      moduleTypeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isSessionKeyLive(
      _sessionKey: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isValidSignatureWithSender(
      sender: PromiseOrValue<string>,
      hash: PromiseOrValue<BytesLike>,
      data: PromiseOrValue<BytesLike>,
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

    rotateSessionKey(
      _oldSessionKey: PromiseOrValue<string>,
      _newSessionData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    sessionData(
      sessionKey: PromiseOrValue<string>,
      wallet: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    toggleSessionKeyPause(
      _sessionKey: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    validateSessionKeyParams(
      _sessionKey: PromiseOrValue<string>,
      userOp: PackedUserOperationStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    validateUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    walletSessionKeys(
      wallet: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    disableSessionKey(
      _session: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    enableSessionKey(
      _sessionData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    getAssociatedSessionKeys(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getSessionKeyData(
      _sessionKey: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    initialized(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isModuleType(
      moduleTypeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isSessionKeyLive(
      _sessionKey: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isValidSignatureWithSender(
      sender: PromiseOrValue<string>,
      hash: PromiseOrValue<BytesLike>,
      data: PromiseOrValue<BytesLike>,
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

    rotateSessionKey(
      _oldSessionKey: PromiseOrValue<string>,
      _newSessionData: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    sessionData(
      sessionKey: PromiseOrValue<string>,
      wallet: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    toggleSessionKeyPause(
      _sessionKey: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    validateSessionKeyParams(
      _sessionKey: PromiseOrValue<string>,
      userOp: PackedUserOperationStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    validateUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    walletSessionKeys(
      wallet: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
