// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title Receiver
 * @dev This contract receives safe-transferred ERC721 and ERC1155 tokens.
 * @author Modified from Solady
 * (https://github.com/Vectorized/solady/blob/main/src/accounts/Receiver.sol)
 */
abstract contract Receiver {
    /// @dev For receiving ETH.
    receive() external payable virtual {}

    /// @dev Fallback function with the `receiverFallback` modifier.
    fallback() external payable virtual {}
}
