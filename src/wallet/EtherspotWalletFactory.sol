// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EtherspotWallet.sol";
import "./Proxy.sol";
import "../interfaces/IEtherspotWalletFactory.sol";

/**
 * @title Proxy Factory - Allows to create a new proxy contract and execute a message call to the new proxy within one transaction.
 */
contract EtherspotWalletFactory is IEtherspotWalletFactory {
    address public accountImplementation;
    address public owner;

    event OwnerChanged(address newOwner);

    modifier onlyOwner() {
        require(owner == msg.sender, "EtherspotWalletFactory:: only owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function accountCreationCode() public pure returns (bytes memory) {
        return type(Proxy).creationCode;
    }

    /**
     * @notice Creates a new account
     * @param _owner owner of the account to be deployed
     * @param _index extra salt that allows to deploy more account if needed for same owner
     * @return ret the address of the deployed account
     */
    function createAccount(
        address _owner,
        uint256 _index
    ) external returns (address ret) {
        require(
            accountImplementation != address(0),
            "EtherspotWalletFactory:: implementation not set"
        );
        address account = getAddress(_owner, _index);
        if (account.code.length > 0) {
            return account;
        }

        bytes memory initializer = getInitializer(_owner);

        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(initializer), _index)
        );

        bytes memory deploymentData = abi.encodePacked(
            type(Proxy).creationCode,
            uint256(uint160(accountImplementation))
        );

        // solhint-disable-next-line no-inline-assembly
        assembly {
            ret := create2(
                0x0,
                add(0x20, deploymentData),
                mload(deploymentData),
                salt
            )
        }
        require(address(ret) != address(0), "Create2 call failed");

        // calldata for init method
        if (initializer.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(
                    call(
                        gas(),
                        ret,
                        0,
                        add(initializer, 0x20),
                        mload(initializer),
                        0,
                        0
                    ),
                    0
                ) {
                    revert(0, 0)
                }
            }
        }
        emit AccountCreation(ret, _owner, _index);
    }

    /**
     * @notice Deploys account using create2
     * @param _owner owner of the account to be deployed
     * @param _index extra salt that allows to deploy more account if needed for same owner
     */
    function getAddress(
        address _owner,
        uint256 _index
    ) public view returns (address proxy) {
        require(
            accountImplementation != address(0),
            "EtherspotWalletFactory:: implementation not set"
        );
        bytes memory initializer = getInitializer(_owner);
        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(initializer), _index)
        );
        bytes memory code = abi.encodePacked(
            type(Proxy).creationCode,
            uint256(uint160(accountImplementation))
        );
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(code))
        );
        proxy = address(uint160(uint256(hash)));
    }

    /**
     * @dev Allows to retrieve the initializer data for the account.
     * @param _owner EOA signatory for the account to be deployed
     * @return initializer bytes for init method
     */
    function getInitializer(
        address _owner
    ) internal pure returns (bytes memory) {
        return abi.encodeCall(EtherspotWallet.initialize, (_owner));
    }

    /**
     * @dev Allows to set a new implementation contract address
     * @param _newImpl new implementation EtherspotWalletContract
     */
    function setImplementation(EtherspotWallet _newImpl) external onlyOwner {
        accountImplementation = address(_newImpl);
        emit ImplementationSet(accountImplementation);
    }

    /**
     * @dev Checks implementation address matches address
     * @param _impl address to check against
     * @return boolean (true if accountImplementation == address)
     */
    function checkImplementation(address _impl) external view returns (bool) {
        return accountImplementation == _impl;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(
            _newOwner != address(0),
            "EtherspotWalletFactory:: new owner cannot be zero address"
        );
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}
