// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Owned {
    mapping(address => bool) private owners;

    event OwnerAdded(address newOwner);
    event OwnerRemoved(address removedOwner);

    function isOwner(address _address) public view returns (bool) {
        return owners[_address];
    }

    function _addOwner(address _newOwner) internal {
        // no check for address(0) as used when creating wallet via BLS.
        require(!owners[_newOwner], "Owned:: already an owner");
        emit OwnerAdded(_newOwner);
        owners[_newOwner] = true;
    }

    function _removeOwner(address _owner) internal {
        require(msg.sender != _owner, "Owned:: cannot remove self");
        require(owners[_owner], "Owned:: owner doesn't exist");
        emit OwnerRemoved(_owner);
        owners[_owner] = false;
    }
}
