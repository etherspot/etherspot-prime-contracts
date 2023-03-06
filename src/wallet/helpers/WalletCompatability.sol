// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./AccountRegistry.sol";
import "../../libs/ValidationConstants.sol";

/**
 * @title Account implementation (version 1)
 *
 * @author Stanisław Głogowski <stan@pillarproject.io>
 */
contract WalletCompatability {
    address public _registry;

    event ERC777Received(address from, address to, uint256 amount);

    // ERC1820

    function registry() public view returns (address) {
        return _registry;
    }

    function canImplementInterfaceForAddress(
        bytes32 interfaceHash,
        address addr
    ) external view returns (bytes32) {
        bytes32 result;

        if (
            interfaceHash ==
            ValidationConstants.ERC777_TOKENS_RECIPIENT_INTERFACE_HASH &&
            addr == address(this)
        ) {
            result = ValidationConstants.ERC1820_ACCEPT_MAGIC;
        }

        return result;
    }

    // ERC1271

    function isValidSignature(bytes32 messageHash, bytes calldata signature)
        external
        view
        returns (bytes4)
    {
        return
            AccountRegistry(_registry).isValidAccountSignature(
                address(this),
                messageHash,
                signature
            )
                ? ValidationConstants.ERC1271_VALID_MESSAGE_HASH_SIGNATURE
                : ValidationConstants.ERC1271_INVALID_SIGNATURE;
    }

    function isValidSignature(bytes calldata message, bytes calldata signature)
        external
        view
        returns (bytes4)
    {
        return
            AccountRegistry(_registry).isValidAccountSignature(
                address(this),
                message,
                signature
            )
                ? ValidationConstants.ERC1271_VALID_MESSAGE_SIGNATURE
                : ValidationConstants.ERC1271_INVALID_SIGNATURE;
    }

    // external functions (pure)

    // ERC721

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // ERC1155

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    // ERC777

    function tokensReceived(
        address,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata,
        bytes calldata
    ) external {
        emit ERC777Received(_from, _to, _amount);
    }
}
