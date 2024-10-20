// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC7484 } from "../../../../src/modular-etherspot-wallet/modules/registry/interfaces/IERC7484.sol";

contract ERC7484Registry is IERC7484 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          Check with Registry internal attesters            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    function check(address module) external view {}

    function checkForAccount(address smartAccount, address module) external view {}

    function check(address module, uint256 moduleType) external view {}

    function checkForAccount(
        address smartAccount,
        address module,
        uint256 moduleType
    )
        external
        view
    {
        
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              Check with external attester(s)               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function check(address module, address[] calldata attesters, uint256 threshold) external view {

    }

    function check(
        address module,
        uint256 moduleType,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
    {
    }

    function trustAttesters(uint8 threshold, address[] calldata attesters) external { }
}
