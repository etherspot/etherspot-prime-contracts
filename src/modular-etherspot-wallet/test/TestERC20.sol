// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console2.sol";

contract TestERC20 is ERC20 {
    constructor(address _premintReceiver) ERC20("TestERC20", "TEST") {
        _mint(_premintReceiver, 10 * 10 ** decimals());
    }

    function testTransferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        console2.log("testTransferFrom => from:", from);
        console2.log("testTransferFrom => to:", to);
        console2.log("testTransferFrom => value:", value);

        _transfer(from, to, value);
        return true;
    }

    function invalidFunc() public pure returns (bool) {
        return true;
    }
}
