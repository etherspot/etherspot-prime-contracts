// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract AccessController {
    mapping(address => bool) private owners;
    mapping(address => bool) private guardians;

    event OwnerAdded(address newOwner);
    event OwnerRemoved(address removedOwner);
    event GuardianAdded(address newGuardian);
    event GuardianRemoved(address removedGuardian);

    modifier onlyOwner() {
        require(
            isOwner(msg.sender) || msg.sender == address(this),
            "ACL:: only owner"
        );
        _;
    }

    modifier onlyOwnerOrGuardian() {
        require(
            isOwner(msg.sender) ||
                msg.sender == address(this) ||
                isGuardian(msg.sender),
            "ACL:: only owner or guardian"
        );
        _;
    }

    modifier onlyOwnerOrEntryPoint(address _entryPoint) {
        require(
            msg.sender == _entryPoint || isOwner(msg.sender),
            "ACL:: not owner or entryPoint"
        );
        _;
    }

    function isOwner(address _address) public view returns (bool) {
        return owners[_address];
    }

    function isGuardian(address _address) public view returns (bool) {
        return guardians[_address];
    }

    function addOwner(address _newOwner) external onlyOwnerOrGuardian {
        _addOwner(_newOwner);
    }

    function removeOwner(address _owner) external onlyOwnerOrGuardian {
        _removeOwner(_owner);
    }

    function addGuardian(address _newGuardian) external onlyOwner {
        _addGuardian(_newGuardian);
    }

    function removeGuardian(address _guardian) external onlyOwner {
        _removeGuardian(_guardian);
    }

    // INTERNAL

    function _addOwner(address _newOwner) internal {
        // no check for address(0) as used when creating wallet via BLS.
        require(_newOwner != address(0), "ACL:: zero address");
        require(!owners[_newOwner], "ACL:: already owner");
        emit OwnerAdded(_newOwner);
        owners[_newOwner] = true;
    }

    function _addGuardian(address _newGuardian) internal {
        require(_newGuardian != address(0), "ACL:: zero address");
        require(!guardians[_newGuardian], "ACL:: already guardian");
        emit GuardianAdded(_newGuardian);
        guardians[_newGuardian] = true;
    }

    function _removeOwner(address _owner) internal {
        require(msg.sender != _owner, "ACL:: removing self");
        require(owners[_owner], "ACL:: non-existant owner");
        emit OwnerRemoved(_owner);
        owners[_owner] = false;
    }

    function _removeGuardian(address _guardian) internal {
        require(guardians[_guardian], "ACL:: non-existant guardian");
        emit GuardianRemoved(_guardian);
        guardians[_guardian] = false;
    }
}
