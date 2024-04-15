// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "forge-std/console2.sol";

contract TestERC721 is ERC721 {
    constructor() ERC721("TestERC721", "TEST") {}

    function mint(address _to, uint256 _id) external {
        _mint(_to, _id);
    }
}
