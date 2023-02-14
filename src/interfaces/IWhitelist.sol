// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IWhitelist {
    function check(address _sponsor, address _account)
        external
        view
        returns (bool);

    function add(address _account) external;

    function addBatch(address[] calldata _accounts) external;

    function remove(address _account) external;

    function removeBatch(address[] calldata _accounts) external;
}
