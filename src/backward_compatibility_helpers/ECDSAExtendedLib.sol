// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./StringsLib.sol";

/**
 * @title ECDSA extended library
 */
library ECDSAExtendedLib {
    using StringsLib for uint256;

    function toEthereumSignedMessageHash(bytes memory message)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    message.length.toString(),
                    abi.encodePacked(message)
                )
            );
    }
}
