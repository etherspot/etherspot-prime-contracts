/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { ethers } from 'ethers';
import {
  FactoryOptions,
  HardhatEthersHelpers as HardhatEthersHelpersBase,
} from '@nomiclabs/hardhat-ethers/types';

import * as Contracts from '.';

declare module 'hardhat/types/runtime' {
  interface HardhatEthersHelpers extends HardhatEthersHelpersBase {
    getContractFactory(
      name: 'Ownable',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Ownable__factory>;
    getContractFactory(
      name: 'IERC1822Proxiable',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1822Proxiable__factory>;
    getContractFactory(
      name: 'IERC1155Errors',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1155Errors__factory>;
    getContractFactory(
      name: 'IERC20Errors',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20Errors__factory>;
    getContractFactory(
      name: 'IERC721Errors',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC721Errors__factory>;
    getContractFactory(
      name: 'IBeacon',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IBeacon__factory>;
    getContractFactory(
      name: 'ERC1967Utils',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC1967Utils__factory>;
    getContractFactory(
      name: 'Initializable',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Initializable__factory>;
    getContractFactory(
      name: 'UUPSUpgradeable',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.UUPSUpgradeable__factory>;
    getContractFactory(
      name: 'IERC1155Receiver',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1155Receiver__factory>;
    getContractFactory(
      name: 'ERC20',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC20__factory>;
    getContractFactory(
      name: 'IERC20Metadata',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20Metadata__factory>;
    getContractFactory(
      name: 'IERC20',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20__factory>;
    getContractFactory(
      name: 'IERC721Receiver',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC721Receiver__factory>;
    getContractFactory(
      name: 'Address',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Address__factory>;
    getContractFactory(
      name: 'ECDSA',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ECDSA__factory>;
    getContractFactory(
      name: 'ERC165',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC165__factory>;
    getContractFactory(
      name: 'IERC165',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC165__factory>;
    getContractFactory(
      name: 'Math',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Math__factory>;
    getContractFactory(
      name: 'ReentrancyGuard',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ReentrancyGuard__factory>;
    getContractFactory(
      name: 'Strings',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Strings__factory>;
    getContractFactory(
      name: 'BaseAccount',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.BaseAccount__factory>;
    getContractFactory(
      name: 'BasePaymaster',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.BasePaymaster__factory>;
    getContractFactory(
      name: 'EntryPoint',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EntryPoint__factory>;
    getContractFactory(
      name: 'EntryPointSimulations',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EntryPointSimulations__factory>;
    getContractFactory(
      name: 'NonceManager',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.NonceManager__factory>;
    getContractFactory(
      name: 'SenderCreator',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.SenderCreator__factory>;
    getContractFactory(
      name: 'StakeManager',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.StakeManager__factory>;
    getContractFactory(
      name: 'UserOperationLib',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.UserOperationLib__factory>;
    getContractFactory(
      name: 'IAccount',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccount__factory>;
    getContractFactory(
      name: 'IAccountExecute',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccountExecute__factory>;
    getContractFactory(
      name: 'IAggregator',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAggregator__factory>;
    getContractFactory(
      name: 'IEntryPoint',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IEntryPoint__factory>;
    getContractFactory(
      name: 'IEntryPointSimulations',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IEntryPointSimulations__factory>;
    getContractFactory(
      name: 'INonceManager',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.INonceManager__factory>;
    getContractFactory(
      name: 'IPaymaster',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IPaymaster__factory>;
    getContractFactory(
      name: 'IStakeManager',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IStakeManager__factory>;
    getContractFactory(
      name: 'TokenCallbackHandler',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.TokenCallbackHandler__factory>;
    getContractFactory(
      name: 'DSTest',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.DSTest__factory>;
    getContractFactory(
      name: 'IERC165',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC165__factory>;
    getContractFactory(
      name: 'IMulticall3',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IMulticall3__factory>;
    getContractFactory(
      name: 'StdAssertions',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.StdAssertions__factory>;
    getContractFactory(
      name: 'StdError',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.StdError__factory>;
    getContractFactory(
      name: 'StdInvariant',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.StdInvariant__factory>;
    getContractFactory(
      name: 'StdStorageSafe',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.StdStorageSafe__factory>;
    getContractFactory(
      name: 'Test',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Test__factory>;
    getContractFactory(
      name: 'Vm',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Vm__factory>;
    getContractFactory(
      name: 'VmSafe',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.VmSafe__factory>;
    getContractFactory(
      name: 'Ownable',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Ownable__factory>;
    getContractFactory(
      name: 'ECDSA',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ECDSA__factory>;
    getContractFactory(
      name: 'EIP712',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EIP712__factory>;
    getContractFactory(
      name: 'LibClone',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.LibClone__factory>;
    getContractFactory(
      name: 'AccessController',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.AccessController__factory>;
    getContractFactory(
      name: 'UniversalSigValidator',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.UniversalSigValidator__factory>;
    getContractFactory(
      name: 'ValidateSigOffchain',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ValidateSigOffchain__factory>;
    getContractFactory(
      name: 'IAccessController',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccessController__factory>;
    getContractFactory(
      name: 'IERC1271Wallet',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1271Wallet__factory>;
    getContractFactory(
      name: 'IEtherspotPaymaster',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IEtherspotPaymaster__factory>;
    getContractFactory(
      name: 'IEtherspotWallet',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IEtherspotWallet__factory>;
    getContractFactory(
      name: 'IEtherspotWalletFactory',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IEtherspotWalletFactory__factory>;
    getContractFactory(
      name: 'IWhitelist',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IWhitelist__factory>;
    getContractFactory(
      name: 'BasePaymaster',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.BasePaymaster__factory>;
    getContractFactory(
      name: 'EtherspotPaymaster',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EtherspotPaymaster__factory>;
    getContractFactory(
      name: 'VerifyingPaymaster',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.VerifyingPaymaster__factory>;
    getContractFactory(
      name: 'Whitelist',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Whitelist__factory>;
    getContractFactory(
      name: 'EtherspotWallet',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EtherspotWallet__factory>;
    getContractFactory(
      name: 'EtherspotWalletFactory',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EtherspotWalletFactory__factory>;
    getContractFactory(
      name: 'Proxy',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Proxy__factory>;
    getContractFactory(
      name: 'AccessController',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.AccessController__factory>;
    getContractFactory(
      name: 'AccountBase',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.AccountBase__factory>;
    getContractFactory(
      name: 'ExecutionHelper',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ExecutionHelper__factory>;
    getContractFactory(
      name: 'HookManager',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.HookManager__factory>;
    getContractFactory(
      name: 'ModuleManager',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ModuleManager__factory>;
    getContractFactory(
      name: 'Receiver',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Receiver__factory>;
    getContractFactory(
      name: 'IERC7579Account',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC7579Account__factory>;
    getContractFactory(
      name: 'IExecutor',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IExecutor__factory>;
    getContractFactory(
      name: 'IFallback',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IFallback__factory>;
    getContractFactory(
      name: 'IHook',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IHook__factory>;
    getContractFactory(
      name: 'IModule',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IModule__factory>;
    getContractFactory(
      name: 'IValidator',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IValidator__factory>;
    getContractFactory(
      name: 'IMSA',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IMSA__factory>;
    getContractFactory(
      name: 'SentinelListLib',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.SentinelListLib__factory>;
    getContractFactory(
      name: 'BootstrapUtil',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.BootstrapUtil__factory>;
    getContractFactory(
      name: 'EntryPointSimulationsPatch',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EntryPointSimulationsPatch__factory>;
    getContractFactory(
      name: 'MockDelegateTarget',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.MockDelegateTarget__factory>;
    getContractFactory(
      name: 'MockExecutor',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.MockExecutor__factory>;
    getContractFactory(
      name: 'MockFallback',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.MockFallback__factory>;
    getContractFactory(
      name: 'MockTarget',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.MockTarget__factory>;
    getContractFactory(
      name: 'MockValidator',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.MockValidator__factory>;
    getContractFactory(
      name: 'Bootstrap',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Bootstrap__factory>;
    getContractFactory(
      name: 'IAccessController',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccessController__factory>;
    getContractFactory(
      name: 'IERC20SessionKeyValidator',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20SessionKeyValidator__factory>;
    getContractFactory(
      name: 'IModularEtherspotWallet',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IModularEtherspotWallet__factory>;
    getContractFactory(
      name: 'ErrorsLib',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ErrorsLib__factory>;
    getContractFactory(
      name: 'ERC20Actions',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC20Actions__factory>;
    getContractFactory(
      name: 'ModuleIsolationHook',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ModuleIsolationHook__factory>;
    getContractFactory(
      name: 'ERC20SessionKeyValidator',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC20SessionKeyValidator__factory>;
    getContractFactory(
      name: 'AccessController',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.AccessController__factory>;
    getContractFactory(
      name: 'AccountBase',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.AccountBase__factory>;
    getContractFactory(
      name: 'ECDSA',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ECDSA__factory>;
    getContractFactory(
      name: 'EIP712',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EIP712__factory>;
    getContractFactory(
      name: 'ErrorsLib',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ErrorsLib__factory>;
    getContractFactory(
      name: 'ExecutionHelper',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ExecutionHelper__factory>;
    getContractFactory(
      name: 'HookManager',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.HookManager__factory>;
    getContractFactory(
      name: 'IAccessController',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccessController__factory>;
    getContractFactory(
      name: 'IAccount',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccount__factory>;
    getContractFactory(
      name: 'IERC165',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC165__factory>;
    getContractFactory(
      name: 'IERC7579Account',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC7579Account__factory>;
    getContractFactory(
      name: 'IExecutor',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IExecutor__factory>;
    getContractFactory(
      name: 'IFallback',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IFallback__factory>;
    getContractFactory(
      name: 'IHook',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IHook__factory>;
    getContractFactory(
      name: 'IModularEtherspotWallet',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IModularEtherspotWallet__factory>;
    getContractFactory(
      name: 'IModule',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IModule__factory>;
    getContractFactory(
      name: 'IMSA',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IMSA__factory>;
    getContractFactory(
      name: 'IValidator',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IValidator__factory>;
    getContractFactory(
      name: 'ModularEtherspotWallet',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ModularEtherspotWallet__factory>;
    getContractFactory(
      name: 'ModuleManager',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ModuleManager__factory>;
    getContractFactory(
      name: 'MultipleOwnerECDSAValidator',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.MultipleOwnerECDSAValidator__factory>;
    getContractFactory(
      name: 'Receiver',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Receiver__factory>;
    getContractFactory(
      name: 'SentinelListLib',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.SentinelListLib__factory>;
    getContractFactory(
      name: 'MultipleOwnerECDSAValidator',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.MultipleOwnerECDSAValidator__factory>;
    getContractFactory(
      name: 'TestERC20',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.TestERC20__factory>;
    getContractFactory(
      name: 'TestUSDC',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.TestUSDC__factory>;
    getContractFactory(
      name: 'FactoryStaker',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.FactoryStaker__factory>;
    getContractFactory(
      name: 'ModularEtherspotWallet',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ModularEtherspotWallet__factory>;
    getContractFactory(
      name: 'ModularEtherspotWalletFactory',
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ModularEtherspotWalletFactory__factory>;

    getContractAt(
      name: 'Ownable',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Ownable>;
    getContractAt(
      name: 'IERC1822Proxiable',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1822Proxiable>;
    getContractAt(
      name: 'IERC1155Errors',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1155Errors>;
    getContractAt(
      name: 'IERC20Errors',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20Errors>;
    getContractAt(
      name: 'IERC721Errors',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC721Errors>;
    getContractAt(
      name: 'IBeacon',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IBeacon>;
    getContractAt(
      name: 'ERC1967Utils',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC1967Utils>;
    getContractAt(
      name: 'Initializable',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Initializable>;
    getContractAt(
      name: 'UUPSUpgradeable',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.UUPSUpgradeable>;
    getContractAt(
      name: 'IERC1155Receiver',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1155Receiver>;
    getContractAt(
      name: 'ERC20',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC20>;
    getContractAt(
      name: 'IERC20Metadata',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20Metadata>;
    getContractAt(
      name: 'IERC20',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20>;
    getContractAt(
      name: 'IERC721Receiver',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC721Receiver>;
    getContractAt(
      name: 'Address',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Address>;
    getContractAt(
      name: 'ECDSA',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ECDSA>;
    getContractAt(
      name: 'ERC165',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC165>;
    getContractAt(
      name: 'IERC165',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC165>;
    getContractAt(
      name: 'Math',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Math>;
    getContractAt(
      name: 'ReentrancyGuard',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ReentrancyGuard>;
    getContractAt(
      name: 'Strings',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Strings>;
    getContractAt(
      name: 'BaseAccount',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.BaseAccount>;
    getContractAt(
      name: 'BasePaymaster',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.BasePaymaster>;
    getContractAt(
      name: 'EntryPoint',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EntryPoint>;
    getContractAt(
      name: 'EntryPointSimulations',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EntryPointSimulations>;
    getContractAt(
      name: 'NonceManager',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.NonceManager>;
    getContractAt(
      name: 'SenderCreator',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.SenderCreator>;
    getContractAt(
      name: 'StakeManager',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.StakeManager>;
    getContractAt(
      name: 'UserOperationLib',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.UserOperationLib>;
    getContractAt(
      name: 'IAccount',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccount>;
    getContractAt(
      name: 'IAccountExecute',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccountExecute>;
    getContractAt(
      name: 'IAggregator',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAggregator>;
    getContractAt(
      name: 'IEntryPoint',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IEntryPoint>;
    getContractAt(
      name: 'IEntryPointSimulations',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IEntryPointSimulations>;
    getContractAt(
      name: 'INonceManager',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.INonceManager>;
    getContractAt(
      name: 'IPaymaster',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IPaymaster>;
    getContractAt(
      name: 'IStakeManager',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IStakeManager>;
    getContractAt(
      name: 'TokenCallbackHandler',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.TokenCallbackHandler>;
    getContractAt(
      name: 'DSTest',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.DSTest>;
    getContractAt(
      name: 'IERC165',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC165>;
    getContractAt(
      name: 'IMulticall3',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IMulticall3>;
    getContractAt(
      name: 'StdAssertions',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.StdAssertions>;
    getContractAt(
      name: 'StdError',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.StdError>;
    getContractAt(
      name: 'StdInvariant',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.StdInvariant>;
    getContractAt(
      name: 'StdStorageSafe',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.StdStorageSafe>;
    getContractAt(
      name: 'Test',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Test>;
    getContractAt(
      name: 'Vm',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Vm>;
    getContractAt(
      name: 'VmSafe',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.VmSafe>;
    getContractAt(
      name: 'Ownable',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Ownable>;
    getContractAt(
      name: 'ECDSA',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ECDSA>;
    getContractAt(
      name: 'EIP712',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EIP712>;
    getContractAt(
      name: 'LibClone',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.LibClone>;
    getContractAt(
      name: 'AccessController',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.AccessController>;
    getContractAt(
      name: 'UniversalSigValidator',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.UniversalSigValidator>;
    getContractAt(
      name: 'ValidateSigOffchain',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ValidateSigOffchain>;
    getContractAt(
      name: 'IAccessController',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccessController>;
    getContractAt(
      name: 'IERC1271Wallet',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1271Wallet>;
    getContractAt(
      name: 'IEtherspotPaymaster',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IEtherspotPaymaster>;
    getContractAt(
      name: 'IEtherspotWallet',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IEtherspotWallet>;
    getContractAt(
      name: 'IEtherspotWalletFactory',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IEtherspotWalletFactory>;
    getContractAt(
      name: 'IWhitelist',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IWhitelist>;
    getContractAt(
      name: 'BasePaymaster',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.BasePaymaster>;
    getContractAt(
      name: 'EtherspotPaymaster',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EtherspotPaymaster>;
    getContractAt(
      name: 'VerifyingPaymaster',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.VerifyingPaymaster>;
    getContractAt(
      name: 'Whitelist',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Whitelist>;
    getContractAt(
      name: 'EtherspotWallet',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EtherspotWallet>;
    getContractAt(
      name: 'EtherspotWalletFactory',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EtherspotWalletFactory>;
    getContractAt(
      name: 'Proxy',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Proxy>;
    getContractAt(
      name: 'AccessController',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.AccessController>;
    getContractAt(
      name: 'AccountBase',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.AccountBase>;
    getContractAt(
      name: 'ExecutionHelper',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ExecutionHelper>;
    getContractAt(
      name: 'HookManager',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.HookManager>;
    getContractAt(
      name: 'ModuleManager',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ModuleManager>;
    getContractAt(
      name: 'Receiver',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Receiver>;
    getContractAt(
      name: 'IERC7579Account',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC7579Account>;
    getContractAt(
      name: 'IExecutor',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IExecutor>;
    getContractAt(
      name: 'IFallback',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IFallback>;
    getContractAt(
      name: 'IHook',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IHook>;
    getContractAt(
      name: 'IModule',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IModule>;
    getContractAt(
      name: 'IValidator',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IValidator>;
    getContractAt(
      name: 'IMSA',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IMSA>;
    getContractAt(
      name: 'SentinelListLib',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.SentinelListLib>;
    getContractAt(
      name: 'BootstrapUtil',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.BootstrapUtil>;
    getContractAt(
      name: 'EntryPointSimulationsPatch',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EntryPointSimulationsPatch>;
    getContractAt(
      name: 'MockDelegateTarget',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.MockDelegateTarget>;
    getContractAt(
      name: 'MockExecutor',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.MockExecutor>;
    getContractAt(
      name: 'MockFallback',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.MockFallback>;
    getContractAt(
      name: 'MockTarget',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.MockTarget>;
    getContractAt(
      name: 'MockValidator',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.MockValidator>;
    getContractAt(
      name: 'Bootstrap',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Bootstrap>;
    getContractAt(
      name: 'IAccessController',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccessController>;
    getContractAt(
      name: 'IERC20SessionKeyValidator',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20SessionKeyValidator>;
    getContractAt(
      name: 'IModularEtherspotWallet',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IModularEtherspotWallet>;
    getContractAt(
      name: 'ErrorsLib',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ErrorsLib>;
    getContractAt(
      name: 'ERC20Actions',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC20Actions>;
    getContractAt(
      name: 'ModuleIsolationHook',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ModuleIsolationHook>;
    getContractAt(
      name: 'ERC20SessionKeyValidator',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC20SessionKeyValidator>;
    getContractAt(
      name: 'AccessController',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.AccessController>;
    getContractAt(
      name: 'AccountBase',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.AccountBase>;
    getContractAt(
      name: 'ECDSA',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ECDSA>;
    getContractAt(
      name: 'EIP712',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EIP712>;
    getContractAt(
      name: 'ErrorsLib',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ErrorsLib>;
    getContractAt(
      name: 'ExecutionHelper',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ExecutionHelper>;
    getContractAt(
      name: 'HookManager',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.HookManager>;
    getContractAt(
      name: 'IAccessController',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccessController>;
    getContractAt(
      name: 'IAccount',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccount>;
    getContractAt(
      name: 'IERC165',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC165>;
    getContractAt(
      name: 'IERC7579Account',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC7579Account>;
    getContractAt(
      name: 'IExecutor',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IExecutor>;
    getContractAt(
      name: 'IFallback',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IFallback>;
    getContractAt(
      name: 'IHook',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IHook>;
    getContractAt(
      name: 'IModularEtherspotWallet',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IModularEtherspotWallet>;
    getContractAt(
      name: 'IModule',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IModule>;
    getContractAt(
      name: 'IMSA',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IMSA>;
    getContractAt(
      name: 'IValidator',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IValidator>;
    getContractAt(
      name: 'ModularEtherspotWallet',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ModularEtherspotWallet>;
    getContractAt(
      name: 'ModuleManager',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ModuleManager>;
    getContractAt(
      name: 'MultipleOwnerECDSAValidator',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.MultipleOwnerECDSAValidator>;
    getContractAt(
      name: 'Receiver',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Receiver>;
    getContractAt(
      name: 'SentinelListLib',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.SentinelListLib>;
    getContractAt(
      name: 'MultipleOwnerECDSAValidator',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.MultipleOwnerECDSAValidator>;
    getContractAt(
      name: 'TestERC20',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.TestERC20>;
    getContractAt(
      name: 'TestUSDC',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.TestUSDC>;
    getContractAt(
      name: 'FactoryStaker',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.FactoryStaker>;
    getContractAt(
      name: 'ModularEtherspotWallet',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ModularEtherspotWallet>;
    getContractAt(
      name: 'ModularEtherspotWalletFactory',
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ModularEtherspotWalletFactory>;

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
