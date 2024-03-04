/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { ethers } from "ethers";
import {
  FactoryOptions,
  HardhatEthersHelpers as HardhatEthersHelpersBase,
} from "@nomiclabs/hardhat-ethers/types";

import * as Contracts from ".";

declare module "hardhat/types/runtime" {
  interface HardhatEthersHelpers extends HardhatEthersHelpersBase {
    getContractFactory(
      name: "Ownable",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Ownable__factory>;
    getContractFactory(
      name: "IERC1822Proxiable",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1822Proxiable__factory>;
    getContractFactory(
      name: "IERC1967",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1967__factory>;
    getContractFactory(
      name: "IBeacon",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IBeacon__factory>;
    getContractFactory(
      name: "ERC1967Upgrade",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC1967Upgrade__factory>;
    getContractFactory(
      name: "Initializable",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Initializable__factory>;
    getContractFactory(
      name: "UUPSUpgradeable",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.UUPSUpgradeable__factory>;
    getContractFactory(
      name: "IERC1155Receiver",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1155Receiver__factory>;
    getContractFactory(
      name: "IERC721Receiver",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC721Receiver__factory>;
    getContractFactory(
      name: "IERC777Recipient",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC777Recipient__factory>;
    getContractFactory(
      name: "IERC165",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC165__factory>;
    getContractFactory(
      name: "BaseAccount",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.BaseAccount__factory>;
    getContractFactory(
      name: "IAccount",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccount__factory>;
    getContractFactory(
      name: "IAggregator",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAggregator__factory>;
    getContractFactory(
      name: "IEntryPoint",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IEntryPoint__factory>;
    getContractFactory(
      name: "INonceManager",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.INonceManager__factory>;
    getContractFactory(
      name: "IPaymaster",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IPaymaster__factory>;
    getContractFactory(
      name: "IStakeManager",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IStakeManager__factory>;
    getContractFactory(
      name: "TokenCallbackHandler",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.TokenCallbackHandler__factory>;
    getContractFactory(
      name: "SentinelListLib",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.SentinelListLib__factory>;
    getContractFactory(
      name: "ECDSA",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ECDSA__factory>;
    getContractFactory(
      name: "LibClone",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.LibClone__factory>;
    getContractFactory(
      name: "AccountBase",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.AccountBase__factory>;
    getContractFactory(
      name: "Fallback",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Fallback__factory>;
    getContractFactory(
      name: "ModuleManager",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ModuleManager__factory>;
    getContractFactory(
      name: "IERC4337",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC4337__factory>;
    getContractFactory(
      name: "IExecutor",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IExecutor__factory>;
    getContractFactory(
      name: "IFallback",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IFallback__factory>;
    getContractFactory(
      name: "IHook",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IHook__factory>;
    getContractFactory(
      name: "IModule",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IModule__factory>;
    getContractFactory(
      name: "IValidator",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IValidator__factory>;
    getContractFactory(
      name: "IAccountConfig_Hook",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccountConfig_Hook__factory>;
    getContractFactory(
      name: "IAccountConfig",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccountConfig__factory>;
    getContractFactory(
      name: "IExecution",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IExecution__factory>;
    getContractFactory(
      name: "IExecutionUnsafe",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IExecutionUnsafe__factory>;
    getContractFactory(
      name: "IMSA",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IMSA__factory>;
    getContractFactory(
      name: "IERC165",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC165__factory>;
    getContractFactory(
      name: "AccessController",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.AccessController__factory>;
    getContractFactory(
      name: "AccessController",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.AccessController__factory>;
    getContractFactory(
      name: "IAccessController",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccessController__factory>;
    getContractFactory(
      name: "IAccountConfig_Hook",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccountConfig_Hook__factory>;
    getContractFactory(
      name: "IAccountConfig",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccountConfig__factory>;
    getContractFactory(
      name: "IEtherspotWallet7579",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IEtherspotWallet7579__factory>;
    getContractFactory(
      name: "IExecution",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IExecution__factory>;
    getContractFactory(
      name: "IExecutionUnsafe",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IExecutionUnsafe__factory>;
    getContractFactory(
      name: "ErrorsLib",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ErrorsLib__factory>;
    getContractFactory(
      name: "MultipleOwnerECDSAValidator",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.MultipleOwnerECDSAValidator__factory>;
    getContractFactory(
      name: "EtherspotWallet7579",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EtherspotWallet7579__factory>;
    getContractFactory(
      name: "EtherspotWallet7579Base",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EtherspotWallet7579Base__factory>;
    getContractFactory(
      name: "EtherspotWallet7579Factory",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EtherspotWallet7579Factory__factory>;
    getContractFactory(
      name: "UniversalSigValidator",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.UniversalSigValidator__factory>;
    getContractFactory(
      name: "ValidateSigOffchain",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ValidateSigOffchain__factory>;
    getContractFactory(
      name: "IAccessController",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccessController__factory>;
    getContractFactory(
      name: "IERC1271Wallet",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1271Wallet__factory>;
    getContractFactory(
      name: "IEtherspotPaymaster",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IEtherspotPaymaster__factory>;
    getContractFactory(
      name: "IEtherspotWallet",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IEtherspotWallet__factory>;
    getContractFactory(
      name: "IEtherspotWalletFactory",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IEtherspotWalletFactory__factory>;
    getContractFactory(
      name: "IWhitelist",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IWhitelist__factory>;
    getContractFactory(
      name: "BasePaymaster",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.BasePaymaster__factory>;
    getContractFactory(
      name: "EtherspotPaymaster",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EtherspotPaymaster__factory>;
    getContractFactory(
      name: "Whitelist",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Whitelist__factory>;
    getContractFactory(
      name: "EtherspotWallet",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EtherspotWallet__factory>;
    getContractFactory(
      name: "EtherspotWalletFactory",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EtherspotWalletFactory__factory>;
    getContractFactory(
      name: "Proxy",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Proxy__factory>;

    getContractAt(
      name: "Ownable",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Ownable>;
    getContractAt(
      name: "IERC1822Proxiable",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1822Proxiable>;
    getContractAt(
      name: "IERC1967",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1967>;
    getContractAt(
      name: "IBeacon",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IBeacon>;
    getContractAt(
      name: "ERC1967Upgrade",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC1967Upgrade>;
    getContractAt(
      name: "Initializable",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Initializable>;
    getContractAt(
      name: "UUPSUpgradeable",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.UUPSUpgradeable>;
    getContractAt(
      name: "IERC1155Receiver",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1155Receiver>;
    getContractAt(
      name: "IERC721Receiver",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC721Receiver>;
    getContractAt(
      name: "IERC777Recipient",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC777Recipient>;
    getContractAt(
      name: "IERC165",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC165>;
    getContractAt(
      name: "BaseAccount",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.BaseAccount>;
    getContractAt(
      name: "IAccount",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccount>;
    getContractAt(
      name: "IAggregator",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAggregator>;
    getContractAt(
      name: "IEntryPoint",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IEntryPoint>;
    getContractAt(
      name: "INonceManager",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.INonceManager>;
    getContractAt(
      name: "IPaymaster",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IPaymaster>;
    getContractAt(
      name: "IStakeManager",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IStakeManager>;
    getContractAt(
      name: "TokenCallbackHandler",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.TokenCallbackHandler>;
    getContractAt(
      name: "SentinelListLib",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.SentinelListLib>;
    getContractAt(
      name: "ECDSA",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ECDSA>;
    getContractAt(
      name: "LibClone",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.LibClone>;
    getContractAt(
      name: "AccountBase",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.AccountBase>;
    getContractAt(
      name: "Fallback",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Fallback>;
    getContractAt(
      name: "ModuleManager",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ModuleManager>;
    getContractAt(
      name: "IERC4337",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC4337>;
    getContractAt(
      name: "IExecutor",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IExecutor>;
    getContractAt(
      name: "IFallback",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IFallback>;
    getContractAt(
      name: "IHook",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IHook>;
    getContractAt(
      name: "IModule",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IModule>;
    getContractAt(
      name: "IValidator",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IValidator>;
    getContractAt(
      name: "IAccountConfig_Hook",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccountConfig_Hook>;
    getContractAt(
      name: "IAccountConfig",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccountConfig>;
    getContractAt(
      name: "IExecution",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IExecution>;
    getContractAt(
      name: "IExecutionUnsafe",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IExecutionUnsafe>;
    getContractAt(
      name: "IMSA",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IMSA>;
    getContractAt(
      name: "IERC165",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC165>;
    getContractAt(
      name: "AccessController",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.AccessController>;
    getContractAt(
      name: "AccessController",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.AccessController>;
    getContractAt(
      name: "IAccessController",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccessController>;
    getContractAt(
      name: "IAccountConfig_Hook",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccountConfig_Hook>;
    getContractAt(
      name: "IAccountConfig",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccountConfig>;
    getContractAt(
      name: "IEtherspotWallet7579",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IEtherspotWallet7579>;
    getContractAt(
      name: "IExecution",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IExecution>;
    getContractAt(
      name: "IExecutionUnsafe",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IExecutionUnsafe>;
    getContractAt(
      name: "ErrorsLib",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ErrorsLib>;
    getContractAt(
      name: "MultipleOwnerECDSAValidator",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.MultipleOwnerECDSAValidator>;
    getContractAt(
      name: "EtherspotWallet7579",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EtherspotWallet7579>;
    getContractAt(
      name: "EtherspotWallet7579Base",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EtherspotWallet7579Base>;
    getContractAt(
      name: "EtherspotWallet7579Factory",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EtherspotWallet7579Factory>;
    getContractAt(
      name: "UniversalSigValidator",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.UniversalSigValidator>;
    getContractAt(
      name: "ValidateSigOffchain",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ValidateSigOffchain>;
    getContractAt(
      name: "IAccessController",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccessController>;
    getContractAt(
      name: "IERC1271Wallet",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1271Wallet>;
    getContractAt(
      name: "IEtherspotPaymaster",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IEtherspotPaymaster>;
    getContractAt(
      name: "IEtherspotWallet",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IEtherspotWallet>;
    getContractAt(
      name: "IEtherspotWalletFactory",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IEtherspotWalletFactory>;
    getContractAt(
      name: "IWhitelist",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IWhitelist>;
    getContractAt(
      name: "BasePaymaster",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.BasePaymaster>;
    getContractAt(
      name: "EtherspotPaymaster",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EtherspotPaymaster>;
    getContractAt(
      name: "Whitelist",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Whitelist>;
    getContractAt(
      name: "EtherspotWallet",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EtherspotWallet>;
    getContractAt(
      name: "EtherspotWalletFactory",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EtherspotWalletFactory>;
    getContractAt(
      name: "Proxy",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Proxy>;

    // default types
    getContractFactory(
      name: string,
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<ethers.ContractFactory>;
    getContractFactory(
      abi: any[],
      bytecode: ethers.utils.BytesLike,
      signer?: ethers.Signer
    ): Promise<ethers.ContractFactory>;
    getContractAt(
      nameOrAbi: string | any[],
      address: string,
      signer?: ethers.Signer
    ): Promise<ethers.Contract>;
  }
}
