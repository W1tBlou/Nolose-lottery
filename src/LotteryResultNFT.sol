// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract LotteryResultNFT is ERC721URIStorage, Ownable {
    using Strings for uint256;

    uint256 private _tokenIdCounter = 1;
    mapping(uint256 => uint256) public voteToToken;
    address public lotterySystem;

    constructor() ERC721("Lottery Result", "LOTTERY") Ownable(msg.sender) {}

    function setLotterySystem(address _lotterySystem) external onlyOwner {
        lotterySystem = _lotterySystem;
    }

    function mintLotteryResult(
        uint256 lotteryId,
        address winner,
        uint256 yield
    ) external returns (uint256) {
        require(msg.sender == lotterySystem, "Only lottery system can mint");
        require(voteToToken[lotteryId] == 0, "NFT already minted for this lottery");

        uint256 tokenId = _tokenIdCounter++;

        string memory tokenURI = generateSimpleTokenURI(lotteryId, winner, yield);

        _mint(winner, tokenId);
        _setTokenURI(tokenId, tokenURI);

        voteToToken[lotteryId] = tokenId;

        return tokenId;
    }

    function generateSimpleTokenURI(
        uint256 lotteryId,
        address winner,
        uint256 yield
    ) internal pure returns (string memory) {
        bytes memory json = abi.encodePacked(
            '{"name": "Lottery #',
            lotteryId.toString(),
            '", "attributes": [{"trait_type": "Winner", "value": ',
            Strings.toHexString(uint160(winner), 20),
            '}, {"trait_type": "Yield", "value": ',
            yield.toString(),
            '"}]}'
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }
}
