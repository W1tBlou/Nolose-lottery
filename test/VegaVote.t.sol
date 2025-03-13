// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/VegaVote.sol";

contract VegaVoteTest is Test {
    VegaVote public vegaVote;
    address public owner;
    address public user1;
    address public user2;

    uint256 public initialSupply = 1_000_000 * 10 ** 18;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vegaVote = new VegaVote(initialSupply);

        // Transfer some tokens to users for testing
        vegaVote.transfer(user1, 10_000 * 10 ** 18);
        vegaVote.transfer(user2, 5_000 * 10 ** 18);
    }

    function testInitialSupply() public {
        assertEq(vegaVote.totalSupply(), initialSupply);
        assertEq(vegaVote.balanceOf(owner), initialSupply - 15_000 * 10 ** 18);
        assertEq(vegaVote.balanceOf(user1), 10_000 * 10 ** 18);
        assertEq(vegaVote.balanceOf(user2), 5_000 * 10 ** 18);
    }

    function testStaking() public {
        uint256 stakeAmount = 1_000 * 10 ** 18;
        uint256 stakePeriod = 2 * 365 days;

        vm.startPrank(user1);

        // Check initial state
        assertEq(vegaVote.balanceOf(user1), 10_000 * 10 ** 18);
        assertEq(vegaVote.getStakeCount(user1), 0);

        // Stake tokens
        vegaVote.stake(stakeAmount, stakePeriod);

        // Check state after staking
        assertEq(vegaVote.balanceOf(user1), 9_000 * 10 ** 18);
        assertEq(vegaVote.balanceOf(address(vegaVote)), stakeAmount);
        assertEq(vegaVote.getStakeCount(user1), 1);
        assertEq(vegaVote.totalStaked(), stakeAmount);

        // Get stake details
        VegaVote.Stake[] memory stakes = vegaVote.getStakes(user1);
        assertEq(stakes.length, 1);
        assertEq(stakes[0].amount, stakeAmount);
        assertEq(stakes[0].endTime - stakes[0].startTime, stakePeriod);

        vm.stopPrank();
    }

    function testVotingPower() public {
        uint256 stakeAmount = 1_000 * 10 ** 18;

        vm.startPrank(user1);

        // Stake for 1 year
        vegaVote.stake(stakeAmount, 365 days);

        // Stake for 2 years
        vegaVote.stake(stakeAmount, 2 * 365 days);

        // Stake for 4 years
        vegaVote.stake(stakeAmount, 4 * 365 days);

        // Calculate expected voting power
        // 1 year: 1000 * 1^2 = 1000
        // 2 years: 1000 * 2^2 = 4000
        // 4 years: 1000 * 4^2 = 16000
        // Total: 21000

        // Check voting power
        uint256 power0 = vegaVote.calculateVotingPower(0, user1);
        uint256 power1 = vegaVote.calculateVotingPower(1, user1);
        uint256 power2 = vegaVote.calculateVotingPower(2, user1);
        uint256 totalPower = vegaVote.getTotalVotingPower(user1);

        // Due to the way we calculate years (with 2 decimal precision),
        // the actual values might be slightly different
        assertApproxEqRel(power0, 1000 * 10 ** 18, 0.05e18); // Allow 5% deviation
        assertApproxEqRel(power1, 4000 * 10 ** 18, 0.05e18);
        assertApproxEqRel(power2, 16000 * 10 ** 18, 0.05e18);
        assertApproxEqRel(totalPower, 21000 * 10 ** 18, 0.05e18);

        vm.stopPrank();
    }

    function testUnstaking() public {
        uint256 stakeAmount = 1_000 * 10 ** 18;
        uint256 stakePeriod = 1 days; // Short period for testing

        vm.startPrank(user1);

        // Stake tokens
        vegaVote.stake(stakeAmount, stakePeriod);

        // Try to unstake before period ends
        vm.expectRevert("Staking period not ended");
        vegaVote.unstake(0);

        // Advance time
        vm.warp(block.timestamp + stakePeriod + 1);

        // Unstake
        vegaVote.unstake(0);

        // Check state after unstaking
        assertEq(vegaVote.balanceOf(user1), 10_000 * 10 ** 18);
        assertEq(vegaVote.balanceOf(address(vegaVote)), 0);
        assertEq(vegaVote.totalStaked(), 0);

        // Check stake is zeroed out
        VegaVote.Stake[] memory stakes = vegaVote.getStakes(user1);
        assertEq(stakes[0].amount, 0);

        vm.stopPrank();
    }

    function testStakingValidation() public {
        vm.startPrank(user1);

        // Try to stake 0 tokens
        vm.expectRevert("Cannot stake 0 tokens");
        vegaVote.stake(0, 365 days);

        // Try to stake more than balance
        vm.expectRevert("Insufficient balance");
        vegaVote.stake(20_000 * 10 ** 18, 365 days);

        // Try to stake for too long
        vm.expectRevert("Stake period exceeds maximum");
        vegaVote.stake(1_000 * 10 ** 18, 5 * 365 days);

        vm.stopPrank();
    }
}
