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

export interface MultipleOwnerECDSAValidatorInterface extends utils.Interface {
  functions: {
    "eip712Domain()": FunctionFragment;
    "isInitialized(address)": FunctionFragment;
    "isModuleType(uint256)": FunctionFragment;
    "isValidSignatureWithSender(address,bytes32,bytes)": FunctionFragment;
    "onInstall(bytes)": FunctionFragment;
    "onUninstall(bytes)": FunctionFragment;
    "validateUserOp((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes),bytes32)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "eip712Domain"
      | "isInitialized"
      | "isModuleType"
      | "isValidSignatureWithSender"
      | "onInstall"
      | "onUninstall"
      | "validateUserOp"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "eip712Domain",
    values?: undefined
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
    functionFragment: "isValidSignatureWithSender",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BytesLike>,
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
    functionFragment: "validateUserOp",
    values: [PackedUserOperationStruct, PromiseOrValue<BytesLike>]
  ): string;

  decodeFunctionResult(
    functionFragment: "eip712Domain",
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
  decodeFunctionResult(
    functionFragment: "isValidSignatureWithSender",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "onInstall", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "onUninstall",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "validateUserOp",
    data: BytesLike
  ): Result;

  events: {};
}

export interface MultipleOwnerECDSAValidator extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: MultipleOwnerECDSAValidatorInterface;

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
    eip712Domain(
      overrides?: CallOverrides
    ): Promise<
      [string, string, string, BigNumber, string, string, BigNumber[]] & {
        fields: string;
        name: string;
        version: string;
        chainId: BigNumber;
        verifyingContract: string;
        salt: string;
        extensions: BigNumber[];
      }
    >;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isModuleType(
      typeID: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isValidSignatureWithSender(
      arg0: PromiseOrValue<string>,
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

    validateUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  eip712Domain(
    overrides?: CallOverrides
  ): Promise<
    [string, string, string, BigNumber, string, string, BigNumber[]] & {
      fields: string;
      name: string;
      version: string;
      chainId: BigNumber;
      verifyingContract: string;
      salt: string;
      extensions: BigNumber[];
    }
  >;

  isInitialized(
    smartAccount: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isModuleType(
    typeID: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isValidSignatureWithSender(
    arg0: PromiseOrValue<string>,
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

  validateUserOp(
    userOp: PackedUserOperationStruct,
    userOpHash: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    eip712Domain(
      overrides?: CallOverrides
    ): Promise<
      [string, string, string, BigNumber, string, string, BigNumber[]] & {
        fields: string;
        name: string;
        version: string;
        chainId: BigNumber;
        verifyingContract: string;
        salt: string;
        extensions: BigNumber[];
      }
    >;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isModuleType(
      typeID: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isValidSignatureWithSender(
      arg0: PromiseOrValue<string>,
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

    validateUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  filters: {};

  estimateGas: {
    eip712Domain(overrides?: CallOverrides): Promise<BigNumber>;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isModuleType(
      typeID: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isValidSignatureWithSender(
      arg0: PromiseOrValue<string>,
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

    validateUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    eip712Domain(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    isInitialized(
      smartAccount: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isModuleType(
      typeID: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isValidSignatureWithSender(
      arg0: PromiseOrValue<string>,
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

    validateUserOp(
      userOp: PackedUserOperationStruct,
      userOpHash: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
