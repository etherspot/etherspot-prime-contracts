// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDC is ERC20 {
    constructor() ERC20("TUSDC", "TestUSDC") {}

    function mint(address sender, uint256 amount) external {
        _mint(sender, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
