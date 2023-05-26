// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IWhitelist {
    event WhitelistInitialized(address owner, string version);
    event AddedToWhitelist(address indexed paymaster, address indexed account);
    event AddedBatchToWhitelist(
        address indexed paymaster,
        address[] indexed accounts
    );
    event RemovedFromWhitelist(
        address indexed paymaster,
        address indexed account
    );
    event RemovedBatchFromWhitelist(
        address indexed paymaster,
        address[] indexed accounts
    );

    function check(
        address _sponsor,
        address _account
    ) external view returns (bool);

    function add(address _account) external;

    function addBatch(address[] calldata _accounts) external;

    function remove(address _account) external;

    function removeBatch(address[] calldata _accounts) external;
}
