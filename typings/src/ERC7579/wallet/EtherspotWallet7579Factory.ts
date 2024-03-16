/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  PayableOverrides,
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

export interface EtherspotWallet7579FactoryInterface extends utils.Interface {
  functions: {
    "_getSalt(bytes32,bytes)": FunctionFragment;
    "createAccount(bytes32,bytes)": FunctionFragment;
    "getAddress(bytes32,bytes)": FunctionFragment;
    "implementation()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "_getSalt"
      | "createAccount"
      | "getAddress"
      | "implementation"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "_getSalt",
    values: [PromiseOrValue<BytesLike>, PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "createAccount",
    values: [PromiseOrValue<BytesLike>, PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "getAddress",
    values: [PromiseOrValue<BytesLike>, PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "implementation",
    values?: undefined
  ): string;

  decodeFunctionResult(functionFragment: "_getSalt", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "createAccount",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "getAddress", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "implementation",
    data: BytesLike
  ): Result;

  events: {};
}

export interface EtherspotWallet7579Factory extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: EtherspotWallet7579FactoryInterface;

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
    _getSalt(
      _salt: PromiseOrValue<BytesLike>,
      initCode: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[string] & { salt: string }>;

    createAccount(
      salt: PromiseOrValue<BytesLike>,
      initCode: PromiseOrValue<BytesLike>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    getAddress(
      salt: PromiseOrValue<BytesLike>,
      initcode: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    implementation(overrides?: CallOverrides): Promise<[string]>;
  };

  _getSalt(
    _salt: PromiseOrValue<BytesLike>,
    initCode: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<string>;

  createAccount(
    salt: PromiseOrValue<BytesLike>,
    initCode: PromiseOrValue<BytesLike>,
    overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  getAddress(
    salt: PromiseOrValue<BytesLike>,
    initcode: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<string>;

  implementation(overrides?: CallOverrides): Promise<string>;

  callStatic: {
    _getSalt(
      _salt: PromiseOrValue<BytesLike>,
      initCode: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string>;

    createAccount(
      salt: PromiseOrValue<BytesLike>,
      initCode: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string>;

    getAddress(
      salt: PromiseOrValue<BytesLike>,
      initcode: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string>;

    implementation(overrides?: CallOverrides): Promise<string>;
  };

  filters: {};

  estimateGas: {
    _getSalt(
      _salt: PromiseOrValue<BytesLike>,
      initCode: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    createAccount(
      salt: PromiseOrValue<BytesLike>,
      initCode: PromiseOrValue<BytesLike>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    getAddress(
      salt: PromiseOrValue<BytesLike>,
      initcode: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    implementation(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    _getSalt(
      _salt: PromiseOrValue<BytesLike>,
      initCode: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    createAccount(
      salt: PromiseOrValue<BytesLike>,
      initCode: PromiseOrValue<BytesLike>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    getAddress(
      salt: PromiseOrValue<BytesLike>,
      initcode: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    implementation(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}