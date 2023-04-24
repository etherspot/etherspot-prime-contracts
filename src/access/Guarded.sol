// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Guarded {
    mapping(address => bool) private guardians;

    event GuardianAdded(address newGuardian);
    event GuardianRemoved(address removedGuardian);

    function isGuardian(address _address) public view returns (bool) {
        return guardians[_address];
    }

    function _addGuardian(address _newGuardian) internal {
        require(
            _newGuardian != address(0),
            "Guarded:: zero address can't be guardian"
        );
        require(!guardians[_newGuardian], "Guarded:: already a guardian");
        emit GuardianAdded(_newGuardian);
        guardians[_newGuardian] = true;
    }

    function _removeGuardian(address _guardian) internal {
        require(guardians[_guardian], "Guarded:: guardian doesn't exist");
        emit GuardianRemoved(_guardian);
        guardians[_guardian] = false;
    }
}
