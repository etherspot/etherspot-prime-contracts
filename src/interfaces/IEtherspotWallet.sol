// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IEntryPoint} from "../aa-4337/interfaces/IEntryPoint.sol";

interface IEtherspotWallet {
    event EtherspotWalletInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );
    event EtherspotWalletReceived(address indexed from, uint256 indexed amount);
    event EntryPointChanged(address oldEntryPoint, address newEntryPoint);
    event OwnerAdded(address newOwner, uint256 blockFrom);
    event OwnerRemoved(address removedOwner, uint256 blockFrom);

    function nonce() external view returns (uint256);

    function entryPoint() external view returns (IEntryPoint);

    receive() external payable;

    function execute(address dest, uint256 value, bytes calldata func) external;

    function executeBatch(
        address[] calldata dest,
        bytes[] calldata func
    ) external;

    function getDeposit() external view returns (uint256);

    function addDeposit() external payable;

    function isOwner(address _owner) external view returns (bool);

    function updateEntryPoint(address _newEntryPoint) external;
}
