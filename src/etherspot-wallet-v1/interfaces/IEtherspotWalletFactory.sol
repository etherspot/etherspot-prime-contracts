// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IEtherspotWalletFactory {
    event AccountCreation(
        address indexed wallet,
        address indexed owner,
        uint256 index
    );
    event ImplementationSet(address newImplementation);

    function accountCreationCode() external pure returns (bytes memory);

    function createAccount(
        address _owner,
        uint256 _index
    ) external returns (address ret);

    function getAddress(
        address _owner,
        uint256 _index
    ) external view returns (address proxy);

    function checkImplementation(address _impl) external view returns (bool);
}
