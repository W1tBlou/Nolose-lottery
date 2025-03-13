// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract VotingResultNFT is ERC721URIStorage, Ownable {
    using Strings for uint256;

    uint256 private _tokenIdCounter = 1;
    mapping(uint256 => uint256) public voteToToken;
    address public votingSystem;

    constructor() ERC721("Voting Result", "VOTE") Ownable(msg.sender) {}

    function setVotingSystem(address _votingSystem) external onlyOwner {
        votingSystem = _votingSystem;
    }

    function mintVoteResult(
        uint256 voteId,
        string memory description,
        uint256 yesVotes,
        uint256 noVotes,
        bool passed,
        address recipient
    ) external returns (uint256) {
        require(msg.sender == votingSystem, "Only voting system can mint");
        require(voteToToken[voteId] == 0, "NFT already minted for this vote");

        uint256 tokenId = _tokenIdCounter++;

        string memory tokenURI = generateSimpleTokenURI(voteId, description, yesVotes, noVotes, passed);

        _mint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI);

        voteToToken[voteId] = tokenId;

        return tokenId;
    }

    function generateSimpleTokenURI(
        uint256 voteId,
        string memory description,
        uint256 yesVotes,
        uint256 noVotes,
        bool passed
    ) internal pure returns (string memory) {
        string memory result = passed ? "Passed" : "Failed";

        bytes memory json = abi.encodePacked(
            '{"name": "Vote #',
            voteId.toString(),
            '", "description": "',
            description,
            '", "attributes": [{"trait_type": "Yes Votes", "value": ',
            yesVotes.toString(),
            '}, {"trait_type": "No Votes", "value": ',
            noVotes.toString(),
            '}, {"trait_type": "Result", "value": "',
            result,
            '"}]}'
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }
}
