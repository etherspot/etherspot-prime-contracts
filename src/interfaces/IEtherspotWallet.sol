// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IEntryPoint} from "../../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "../interfaces/IAccessController.sol";

interface IEtherspotWallet is IAccessController {
    event EtherspotWalletInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );
    event EtherspotWalletReceived(address indexed from, uint256 indexed amount);

    function entryPoint() external view returns (IEntryPoint);

    function execute(address dest, uint256 value, bytes calldata func) external;

    function executeBatch(
        address[] calldata dest,
        uint256[] calldata value,
        bytes[] calldata func
    ) external;

    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bytes4 magicValue);

    function getDeposit() external view returns (uint256);

    function addDeposit() external payable;

    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) external;

    receive() external payable;
}
