// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/VegaVote.sol";
import "../src/VotingResultNFT.sol";
import "../src/VotingSystem.sol";
import "../src/VotingPowerManager.sol";

contract VotingSystemTest is Test {
    VegaVote public vegaVote;
    VotingResultNFT public votingResultNFT;
    VotingSystem public votingSystem;
    VotingPowerManager public votingPowerManager;

    address public admin;
    address public user1;
    address public user2;
    address public user3;

    uint256 public initialSupply = 1_000_000 * 10 ** 18;

    function setUp() public {
        admin = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Deploy contracts
        vegaVote = new VegaVote(initialSupply);
        votingResultNFT = new VotingResultNFT();
        votingPowerManager = new VotingPowerManager(address(vegaVote));
        votingSystem = new VotingSystem(address(vegaVote), address(votingPowerManager), address(votingResultNFT));

        // Set up NFT contract
        votingResultNFT.setVotingSystem(address(votingSystem));

        // Transfer tokens to users
        vegaVote.transfer(user1, 10_000 * 10 ** 18);
        vegaVote.transfer(user2, 5_000 * 10 ** 18);
        vegaVote.transfer(user3, 2_000 * 10 ** 18);

        // Users stake tokens for voting power
        vm.startPrank(user1);
        vegaVote.approve(address(votingPowerManager), 5_000 * 10 ** 18);
        votingPowerManager.stake(5_000 * 10 ** 18, 2 * 365 days); // Voting power ~= 20,000
        vm.stopPrank();

        vm.startPrank(user2);
        vegaVote.approve(address(votingPowerManager), 3_000 * 10 ** 18);
        votingPowerManager.stake(3_000 * 10 ** 18, 365 days); // Voting power ~= 3,000
        vm.stopPrank();

        vm.startPrank(user3);
        vegaVote.approve(address(votingPowerManager), 1_000 * 10 ** 18);
        votingPowerManager.stake(1_000 * 10 ** 18, 4 * 365 days); // Voting power ~= 16,000
        vm.stopPrank();
    }

    function testCreateVote() public {
        string memory description = "Should we implement feature X?";
        uint256 duration = 7 days;
        uint256 threshold = 30_000 * 10 ** 18;

        // Create a vote
        votingSystem.createVote(description, duration, threshold);

        // Check vote details
        VotingSystem.Vote memory vote = votingSystem.getVote(1);
        assertEq(vote.id, 1);
        assertEq(vote.description, description);
        assertEq(vote.deadline, block.timestamp + duration);
        assertEq(vote.threshold, threshold);
        assertEq(vote.yesVotes, 0);
        assertEq(vote.noVotes, 0);
        assertEq(vote.finalized, false);
        assertEq(vote.passed, false);
        assertEq(vote.initiator, admin);

        // Check vote count
        assertEq(votingSystem.getVoteCount(), 1);
    }

    function testCastVote() public {
        // Create a vote
        votingSystem.createVote("Test vote", 7 days, 30_000 * 10 ** 18);

        // User1 votes yes
        vm.prank(user1);
        votingSystem.castVote(1, true);

        // User2 votes no
        vm.prank(user2);
        votingSystem.castVote(1, false);

        // Check vote details
        VotingSystem.Vote memory vote = votingSystem.getVote(1);
        assertApproxEqRel(vote.yesVotes, 20_000 * 10 ** 18, 0.05e18); // User1's voting power
        assertApproxEqRel(vote.noVotes, 3_000 * 10 ** 18, 0.05e18); // User2's voting power
        assertEq(vote.finalized, false);
    }

    function testVoteThresholdReached() public {
        // Create a vote with threshold that can be met by user1 and user3 together
        votingSystem.createVote("Test threshold", 7 days, 35_000 * 10 ** 18);

        // User1 votes yes
        vm.prank(user1);
        votingSystem.castVote(1, true);

        // Vote should not be finalized yet
        VotingSystem.Vote memory voteAfterUser1 = votingSystem.getVote(1);
        assertEq(voteAfterUser1.finalized, false);

        // User3 votes yes, which should trigger finalization
        vm.prank(user3);
        votingSystem.castVote(1, true);

        // Check vote is finalized
        VotingSystem.Vote memory voteAfterUser3 = votingSystem.getVote(1);
        assertEq(voteAfterUser3.finalized, true);
        assertEq(voteAfterUser3.passed, true);

        // Check NFT was minted
        uint256 tokenId = votingResultNFT.voteToToken(1);
        assertGt(tokenId, 0);
        assertEq(votingResultNFT.ownerOf(tokenId), admin); // NFT should be owned by the initiator
    }

    function testVoteDeadline() public {
        // Create a vote
        votingSystem.createVote("Test deadline", 1 days, 30_000 * 10 ** 18);

        // User1 votes yes
        vm.prank(user1);
        votingSystem.castVote(1, true);

        // Advance time past deadline
        vm.warp(block.timestamp + 2 days);

        // Try to vote after deadline
        vm.prank(user2);
        vm.expectRevert("Vote deadline passed");
        votingSystem.castVote(1, false);

        // Finalize the vote
        votingSystem.finalizeVote(1);

        // Check vote is finalized
        VotingSystem.Vote memory vote = votingSystem.getVote(1);
        assertEq(vote.finalized, true);
        assertEq(vote.passed, true); // Only yes votes, so it passes
    }

    function testVoteAlreadyFinalized() public {
        // Create and finalize a vote
        votingSystem.createVote("Test finalized", 1 days, 10_000 * 10 ** 18);

        vm.prank(user1);
        votingSystem.castVote(1, true);

        // Vote should be finalized due to threshold
        VotingSystem.Vote memory vote = votingSystem.getVote(1);
        assertEq(vote.finalized, true);

        // Try to vote on finalized vote
        vm.prank(user2);
        vm.expectRevert("Vote already finalized");
        votingSystem.castVote(1, false);

        // Try to finalize again
        vm.expectRevert("Vote already finalized");
        votingSystem.finalizeVote(1);
    }

    function testVoteDoesNotExist() public {
        // Try to vote on non-existent vote
        vm.prank(user1);
        vm.expectRevert("Vote does not exist");
        votingSystem.castVote(999, true);

        // Try to finalize non-existent vote
        vm.expectRevert("Vote does not exist");
        votingSystem.finalizeVote(999);

        // Try to get non-existent vote
        vm.expectRevert("Vote does not exist");
        votingSystem.getVote(999);
    }

    function testIsVoteActive() public {
        // Create a vote
        votingSystem.createVote("Test active", 7 days, 30_000 * 10 ** 18);

        // Check vote is active
        assertEq(votingSystem.isVoteActive(1), true);

        // Finalize vote
        vm.prank(user1);
        votingSystem.castVote(1, true);

        vm.prank(user3);
        votingSystem.castVote(1, true);

        // Check vote is no longer active after finalization
        assertEq(votingSystem.isVoteActive(1), false);
    }

    function testNoVotingPower() public {
        // Create a vote
        votingSystem.createVote("Test no power", 7 days, 30_000 * 10 ** 18);

        // Create a user with no staked tokens
        address noStakeUser = makeAddr("noStakeUser");
        vegaVote.transfer(noStakeUser, 1_000 * 10 ** 18);

        // Try to vote with no voting power
        vm.prank(noStakeUser);
        vm.expectRevert("No voting power");
        votingSystem.castVote(1, true);
    }

    function testAlreadyVoted() public {
        // Create a vote
        votingSystem.createVote("Test already voted", 7 days, 50_000 * 10 ** 18);

        // User1 votes
        vm.prank(user1);
        votingSystem.castVote(1, true);

        // User1 tries to vote again
        vm.prank(user1);
        vm.expectRevert("Already voted");
        votingSystem.castVote(1, false);
    }
}
