// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console2.sol";
contract ERC20Actions {
    error InvalidSelector();
    function transferERC20Action(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) external {
        uint256 allowance = IERC20(_token).allowance(_from, address(this));
        console2.log("ERC20Actions:transferERC20Action");
        bool success = IERC20(_token).transferFrom(_from, _to, _value);
        console2.log("success?", success);
    }

    function invalidSelector() external {
        revert InvalidSelector();
    }
}
