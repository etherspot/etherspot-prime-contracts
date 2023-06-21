// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Generic proxy contract allows to execute all transactions applying the code of a master contract.
 */
contract Proxy {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Constructor function sets address of singleton contract.
     * @param _singleton Singleton address.
     */
    constructor(address _singleton) {
        require(_singleton != address(0), "Invalid address provided");
        assembly {
            sstore(_IMPLEMENTATION_SLOT, _singleton)
        }
    }

    fallback() external payable {
        address target;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            target := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}
