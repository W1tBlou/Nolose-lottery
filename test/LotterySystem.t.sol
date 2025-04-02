// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {LotterySystem} from "../src/LotterySystem.sol";
import {LotteryResultNFT} from "../src/LotteryResultNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

contract LotterySystemTest is Test {
    LotterySystem public lotterySystem;
    LotteryResultNFT public lotteryResultNFT;
    IERC20 public usdc;
    IPool public aavePool;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);

    uint256 public constant INITIAL_BALANCE = 1000 * 10**6; // 1000 USDC (6 decimals)
    uint256 public constant STAKE_AMOUNT = 100 * 10**6; // 100 USDC
    uint256 public constant LOTTERY_DURATION = 1 hours;
    uint256 public constant STAKING_DURATION = 1 hours;

    function setUp() public {
        // Fork mainnet to get real USDC and Aave contracts
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));

        // Get mainnet addresses
        usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC on mainnet
        aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2); // Aave V3 Pool

        // Deploy contracts
        vm.startPrank(owner);
        lotteryResultNFT = new LotteryResultNFT();
        lotterySystem = new LotterySystem(
            address(usdc),
            address(aavePool),
            address(lotteryResultNFT)
        );
        vm.stopPrank();

        // Setup test users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);

        // Deal USDC to test users
        deal(address(usdc), user1, INITIAL_BALANCE);
        deal(address(usdc), user2, INITIAL_BALANCE);
        deal(address(usdc), user3, INITIAL_BALANCE);
    }

    function testCreateLottery() public {
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        assertEq(lotterySystem.getLotteryCount(), 1);
        assertTrue(lotterySystem.isLotteryActive(1));
    }

    function testStake() public {
        // Create lottery
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Approve USDC spending
        vm.startPrank(user1);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT);
        lotterySystem.stake(1, STAKE_AMOUNT);
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(lotterySystem)), STAKE_AMOUNT);
    }

    function testFailStakeAfterDeadline() public {
        // Create lottery
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Move time past staking deadline
        vm.warp(block.timestamp + STAKING_DURATION + 1);

        // Try to stake
        vm.startPrank(user1);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT);
        vm.expectRevert("Staking deadline passed");
        lotterySystem.stake(1, STAKE_AMOUNT);
    }

    function testFinalizeStaking() public {
        // Create lottery
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Stake from multiple users
        vm.startPrank(user1);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT);
        lotterySystem.stake(1, STAKE_AMOUNT);
        vm.stopPrank();

        vm.startPrank(user2);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT);
        lotterySystem.stake(1, STAKE_AMOUNT);
        vm.stopPrank();

        // Move time past staking deadline
        vm.warp(block.timestamp + STAKING_DURATION + 1);

        // Finalize staking
        lotterySystem.finalizeStaking(1);

        // Verify staking is finalized
        (,,,,bool stakingFinalized,,) = lotterySystem.lotteries(1);
        assertTrue(stakingFinalized);
    }

    function testFinalizeLotteryAndWinnerSelection() public {
        // Create lottery
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Stake from multiple users with different amounts
        vm.startPrank(user1);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT * 2);
        lotterySystem.stake(1, STAKE_AMOUNT * 2);
        vm.stopPrank();

        vm.startPrank(user2);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT);
        lotterySystem.stake(1, STAKE_AMOUNT);
        vm.stopPrank();

        vm.startPrank(user3);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT);
        lotterySystem.stake(1, STAKE_AMOUNT);
        vm.stopPrank();

        // Move time past staking deadline
        vm.warp(block.timestamp + STAKING_DURATION + 1);

        // Finalize staking
        lotterySystem.finalizeStaking(1);

        // Move time past lottery deadline
        vm.warp(block.timestamp + LOTTERY_DURATION + 1);

        // Record balances before finalization
        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        uint256 user2BalanceBefore = usdc.balanceOf(user2);
        uint256 user3BalanceBefore = usdc.balanceOf(user3);

        // Finalize lottery
        lotterySystem.finalizeLottery(1);

        // Verify lottery is finalized
        (uint256 id, uint256 deadline, uint256 stakingDeadline, bool finalized, bool stakingFinalized, address winner, address initiator) = lotterySystem.lotteries(1);
        assertTrue(finalized);

        // Get winner
        assertTrue(winner != address(0));

        // Verify NFT was minted
        uint256 tokenId = lotteryResultNFT.voteToToken(1);
        assertTrue(tokenId > 0);
        assertEq(lotteryResultNFT.ownerOf(tokenId), winner);

        // Verify stake returns and yield distribution
        // All users should get their stakes back
        assertEq(usdc.balanceOf(user1), user1BalanceBefore + STAKE_AMOUNT * 2);
        assertEq(usdc.balanceOf(user2), user2BalanceBefore + STAKE_AMOUNT);
        assertEq(usdc.balanceOf(user3), user3BalanceBefore + STAKE_AMOUNT);

        // Winner should have received yield
        assertTrue(usdc.balanceOf(winner) > user1BalanceBefore + STAKE_AMOUNT * 2);
    }

    function testFailFinalizeLotteryBeforeDeadline() public {
        // Create lottery
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Try to finalize before deadline
        vm.expectRevert("Lottery deadline not passed");
        lotterySystem.finalizeLottery(1);
    }

    function testFailFinalizeLotteryBeforeStakingFinalized() public {
        // Create lottery
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Move time past lottery deadline
        vm.warp(block.timestamp + LOTTERY_DURATION + 1);

        // Try to finalize before staking is finalized
        vm.expectRevert("Staking not finalized");
        lotterySystem.finalizeLottery(1);
    }

    function testAaveIntegration() public {
        // Create lottery
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Stake
        vm.startPrank(user1);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT);
        lotterySystem.stake(1, STAKE_AMOUNT);
        vm.stopPrank();

        // Move time past staking deadline
        vm.warp(block.timestamp + STAKING_DURATION + 1);

        // Finalize staking
        lotterySystem.finalizeStaking(1);

        // Verify USDC was supplied to Aave
        assertEq(usdc.balanceOf(address(aavePool)), STAKE_AMOUNT);
    }
}
