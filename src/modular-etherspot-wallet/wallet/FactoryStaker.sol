// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "solady/src/auth/Ownable.sol";
import {IEntryPoint} from "../../../account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract FactoryStaker is Ownable {
    error FactoryStaker_InvalidEPAddress();
    constructor(address _owner) {
        _initializeOwner(_owner);
    }

    function addStake(
        address _epAddress,
        uint32 _unstakeDelaySec
    ) external payable onlyOwner {
        if (_epAddress == address(0)) revert FactoryStaker_InvalidEPAddress();
        IEntryPoint(_epAddress).addStake{value: msg.value}(_unstakeDelaySec);
    }

    function unlockStake(address _epAddress) external onlyOwner {
        if (_epAddress == address(0)) revert FactoryStaker_InvalidEPAddress();
        IEntryPoint(_epAddress).unlockStake();
    }

    function withdrawStake(
        address _epAddress,
        address payable _withdrawTo
    ) external onlyOwner {
        if (_epAddress == address(0)) revert FactoryStaker_InvalidEPAddress();
        IEntryPoint(_epAddress).withdrawStake(_withdrawTo);
    }
}
