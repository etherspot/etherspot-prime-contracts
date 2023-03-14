// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IEntryPoint} from "../aa-4337/interfaces/IEntryPoint.sol";

interface IEtherspotWallet {
    event EtherspotWalletInitialized(
        IEntryPoint indexed entryPoint,
        address indexed registry,
        address indexed owner
    );
    event EntryPointChanged(address oldEntryPoint, address newEntryPoint);
    event RegistryChanged(address oldRegistry, address newRegistry);

    function nonce() external view returns (uint256);

    function entryPoint() external view returns (IEntryPoint);

    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external;

    function executeBatch(address[] calldata dest, bytes[] calldata func)
        external;

    function getDeposit() external view returns (uint256);

    function addDeposit() external payable;

    function updateEntryPoint(address _newEntryPoint) external;

    function updateRegistry(address _newRegistry) external;
}
