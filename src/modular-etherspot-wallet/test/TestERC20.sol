// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("TERC20", "TestERC20") {}

    function mint(address sender, uint256 amount) external {
        _mint(sender, amount);
    }
}
