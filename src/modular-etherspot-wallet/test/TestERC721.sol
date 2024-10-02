// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721 {
    uint256 private _nextTokenId;
    uint256 public immutable PRICE = 0.05 ether;

    event TestNFTPuchased(
        address indexed buyer,
        address indexed receiver,
        uint256 tokenId
    );

    constructor() ERC721("TestNFT", "TNFT") {}

    function purchaseNFTToWallet(address _to) public payable {
        require(msg.value == PRICE, "Invaild purchase price");
        uint256 tokenId = _nextTokenId + 1;
        _safeMint(_to, tokenId);
        emit TestNFTPuchased(msg.sender, _to, tokenId);
    }
}
