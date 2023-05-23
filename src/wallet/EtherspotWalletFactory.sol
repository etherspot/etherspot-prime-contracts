// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EtherspotWallet.sol";
import "./Proxy.sol";

/**
 * @title Proxy Factory - Allows to create a new proxy contract and execute a message call to the new proxy within one transaction.
 */
contract EtherspotWalletFactory {
    event AccountCreation(address indexed wallet, address indexed owner, uint256 index);

    address public immutable accountImplementation;

    constructor() {
        accountImplementation = address(new EtherspotWallet());
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function accountCreationCode() public pure returns (bytes memory) {
        return type(Proxy).creationCode;
    }

    /**
     * @notice Creates a new account
     * @param entryPoint address of the EntryPoint contract
     * @param owner owner of the account to be deployed
     * @param index extra salt that allows to deploy more account if needed for same owner
     * @return ret the address of the deployed account
     */
    function createAccount(
        IEntryPoint entryPoint,
        address owner,
        uint256 index
    ) public returns (address ret) {
        bytes memory initializer = getInitializer(entryPoint, owner);

        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(initializer), index)
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
        emit AccountCreation(ret, owner, index);
    }

    /**
     * @notice Deploys account using create2
     * @param entryPoint address of the EntryPoint contract
     * @param owner owner of the account to be deployed
     * @param index extra salt that allows to deploy more account if needed for same owner
     */
    function getAddress(
        IEntryPoint entryPoint,
        address owner,
        uint256 index
    ) public view returns (address proxy) {
        bytes memory initializer = getInitializer(entryPoint, owner);
        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(initializer), index)
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
     * @param entryPoint EntryPoint contract address
     * @param owner EOA signatory for the account to be deployed
     * @return initializer bytes for init method
     */
    function getInitializer(
        IEntryPoint entryPoint,
        address owner
    ) internal view returns (bytes memory) {
        return abi.encodeCall(
          EtherspotWallet.initialize,
          (entryPoint, owner)
        );
    }
}
