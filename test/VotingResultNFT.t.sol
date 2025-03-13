// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/VotingResultNFT.sol";

contract VotingResultNFTTest is Test {
    VotingResultNFT public votingResultNFT;
    address public owner;
    address public votingSystem;
    address public recipient;

    function setUp() public {
        owner = address(this);
        votingSystem = makeAddr("votingSystem");
        recipient = makeAddr("recipient");

        votingResultNFT = new VotingResultNFT();
        votingResultNFT.setVotingSystem(votingSystem);
    }

    function testSetVotingSystem() public {
        assertEq(votingResultNFT.votingSystem(), votingSystem);

        address newVotingSystem = makeAddr("newVotingSystem");
        votingResultNFT.setVotingSystem(newVotingSystem);
        assertEq(votingResultNFT.votingSystem(), newVotingSystem);
    }

    function testOnlyOwnerCanSetVotingSystem() public {
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert();
        votingResultNFT.setVotingSystem(nonOwner);
    }

    function testMintVoteResult() public {
        uint256 voteId = 1;
        string memory description = "Test Vote";
        uint256 yesVotes = 100;
        uint256 noVotes = 50;
        bool passed = true;

        vm.prank(votingSystem);
        uint256 tokenId = votingResultNFT.mintVoteResult(voteId, description, yesVotes, noVotes, passed, recipient);

        // Check token ownership
        assertEq(votingResultNFT.ownerOf(tokenId), recipient);

        // Check vote to token mapping
        assertEq(votingResultNFT.voteToToken(voteId), tokenId);

        // Check token URI contains vote data
        string memory tokenURI = votingResultNFT.tokenURI(tokenId);
        assertTrue(bytes(tokenURI).length > 0);

        // The tokenURI should be a data URI
        assertTrue(_startsWith(tokenURI, "data:application/json;base64,"));
    }

    function testOnlyVotingSystemCanMint() public {
        uint256 voteId = 1;
        string memory description = "Test Vote";
        uint256 yesVotes = 100;
        uint256 noVotes = 50;
        bool passed = true;

        vm.prank(makeAddr("notVotingSystem"));
        vm.expectRevert("Only voting system can mint");
        votingResultNFT.mintVoteResult(voteId, description, yesVotes, noVotes, passed, recipient);
    }

    function testCannotMintTwiceForSameVote() public {
        uint256 voteId = 1;
        string memory description = "Test Vote";
        uint256 yesVotes = 100;
        uint256 noVotes = 50;
        bool passed = true;

        vm.startPrank(votingSystem);

        votingResultNFT.mintVoteResult(voteId, description, yesVotes, noVotes, passed, recipient);

        vm.expectRevert("NFT already minted for this vote");
        votingResultNFT.mintVoteResult(voteId, description, yesVotes, noVotes, passed, recipient);

        vm.stopPrank();
    }

    // Helper function to check if a string starts with a prefix
    function _startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        if (strBytes.length < prefixBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < prefixBytes.length; i++) {
            if (strBytes[i] != prefixBytes[i]) {
                return false;
            }
        }

        return true;
    }
}
