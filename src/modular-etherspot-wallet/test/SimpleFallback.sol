// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFallback} from "../erc7579-ref-impl/interfaces/IERC7579Module.sol";

contract SimpleFallback is IFallback {
    function onInstall(bytes calldata data) external override {
        // Initialize
    }
    function onUninstall(bytes calldata data) external override {
        // Clean up
    }
    function isModuleType(
        uint256 moduleTypeId
    ) external view override returns (bool) {}
    function isInitialized(address _mew) external view returns (bool) {}
    function performFallbackCall(
        address target
    ) public returns (bool success, bytes memory result) {
        assembly {
            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            let calldataPtr := allocate(calldatasize())
            calldatacopy(calldataPtr, 0, calldatasize())

            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            let senderPtr := allocate(20)
            mstore(senderPtr, shl(96, caller()))

            // Add 20 bytes for the address appended add the end
            success := call(
                gas(),
                target,
                0,
                calldataPtr,
                add(calldatasize(), 20),
                0,
                0
            )

            result := mload(0x40)
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }
}
