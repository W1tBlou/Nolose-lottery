// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/LotteryResultNFT.sol";

contract LotteryResultNFTTest is Test {
    LotteryResultNFT public lotteryResultNFT;
    address public owner;
    address public lotterySystem;
    address public recipient;

    function setUp() public {
        owner = address(this);
        lotterySystem = makeAddr("lotterySystem");
        recipient = makeAddr("recipient");

        lotteryResultNFT = new LotteryResultNFT();
        lotteryResultNFT.setLotterySystem(lotterySystem);
    }

    function testSetLotterySystem() public {
        assertEq(lotteryResultNFT.lotterySystem(), lotterySystem);

        address newLotterySystem = makeAddr("newLotterySystem");
        lotteryResultNFT.setLotterySystem(newLotterySystem);
        assertEq(lotteryResultNFT.lotterySystem(), newLotterySystem);
    }

    function testOnlyOwnerCanSetLotterySystem() public {
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert();
        lotteryResultNFT.setLotterySystem(nonOwner);
    }

    function testMintLotteryResult() public {
        uint256 lotteryId = 1;
        address winner = makeAddr("winner");
        uint256 yield = 100;

        vm.prank(lotterySystem);
        uint256 tokenId = lotteryResultNFT.mintLotteryResult(lotteryId, winner, yield);

        // Check token ownership
        assertEq(lotteryResultNFT.ownerOf(tokenId), winner);

        // Check vote to token mapping
        assertEq(lotteryResultNFT.voteToToken(lotteryId), tokenId);

        // Check token URI contains vote data
        string memory tokenURI = lotteryResultNFT.tokenURI(tokenId);
        assertTrue(bytes(tokenURI).length > 0);

        // The tokenURI should be a data URI
        assertTrue(_startsWith(tokenURI, "data:application/json;base64,"));
    }

    function testOnlyLotterySystemCanMint() public {
        uint256 lotteryId = 1;
        address winner = makeAddr("winner");
        uint256 yield = 100;

        vm.prank(makeAddr("notLotterySystem"));
        vm.expectRevert("Only lottery system can mint");
        lotteryResultNFT.mintLotteryResult(lotteryId, winner, yield);
    }

    function testCannotMintTwiceForSameLottery() public {
        uint256 lotteryId = 1;
        address winner = makeAddr("winner");
        uint256 yield = 100;

        vm.startPrank(lotterySystem);

        lotteryResultNFT.mintLotteryResult(lotteryId, winner, yield);

        vm.expectRevert("NFT already minted for this lottery");
        lotteryResultNFT.mintLotteryResult(lotteryId, winner, yield);

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
