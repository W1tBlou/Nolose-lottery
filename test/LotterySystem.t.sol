// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {LotterySystem} from "../src/LotterySystem.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LotterySystemTest is Test {
    using SafeERC20 for IERC20;

    LotterySystem public lotterySystem;
    IERC20 public usdc;
    IPool public aavePool;

    address public owner = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;
    address public user1 = 0x4260193D14D89836E7e83E2238A091D5a737ffcA;
    address public user2 = 0xC066ac5D385419B1A8c43A0E146fA439837a8B8c;
    address public user3 = 0x46B2Ee09028B2512f10bAeA18A743Ca46A56F658;

    uint256 public constant INITIAL_BALANCE = 1000 * 10 ** 6; // 1000 USDC (6 decimals)
    uint256 public constant STAKE_AMOUNT = 100 * 10 ** 6; // 100 USDC
    uint256 public constant LOTTERY_DURATION = 1 days;
    uint256 public constant STAKING_DURATION = 1 hours;

    function setUp() public {
        // Fork mainnet to get real USDC and Aave contracts
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));

        // Get mainnet addresses
        usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC on mainnet
        aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2); // Aave V3 Pool

        // Deploy contracts
        vm.startPrank(owner);
        lotterySystem = new LotterySystem(address(usdc), address(aavePool));
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

    function test_RevertWhen_StakingAfterDeadline() public {
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
        (,,,, bool stakingFinalized,,,) = lotterySystem.lotteries(1);
        assertTrue(stakingFinalized);
    }

    function testTakeWinningsAndWinnerSelection() public {
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

        // Record balances before taking winnings
        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        uint256 user2BalanceBefore = usdc.balanceOf(user2);
        uint256 user3BalanceBefore = usdc.balanceOf(user3);

        // Take winnings for all users
        vm.startPrank(user1);
        lotterySystem.takeWinnings(1);
        vm.stopPrank();

        vm.startPrank(user2);
        lotterySystem.takeWinnings(1);
        vm.stopPrank();

        vm.startPrank(user3);
        lotterySystem.takeWinnings(1);
        vm.stopPrank();

        // Verify lottery is finalized
        (,,, bool finalized,, address winner,,) = lotterySystem.lotteries(1);
        assertTrue(finalized);

        // Get winner
        assertTrue(winner != address(0));

        // Verify stake returns and yield distribution
        // All users should get their stakes back
        assertTrue(usdc.balanceOf(user1) >= user1BalanceBefore + STAKE_AMOUNT * 2);
        assertTrue(usdc.balanceOf(user2) >= user2BalanceBefore + STAKE_AMOUNT);
        assertTrue(usdc.balanceOf(user3) >= user3BalanceBefore + STAKE_AMOUNT);

        // Winner should have received yield
        if (winner == user1) {
            assertTrue(usdc.balanceOf(user1) > user1BalanceBefore + STAKE_AMOUNT * 2);
        } else if (winner == user2) {
            assertTrue(usdc.balanceOf(user2) > user2BalanceBefore + STAKE_AMOUNT);
        } else if (winner == user3) {
            assertTrue(usdc.balanceOf(user3) > user3BalanceBefore + STAKE_AMOUNT);
        }
    }

    function test_RevertWhen_TakingWinningsBeforeDeadline() public {
        // Create lottery
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Stake
        vm.startPrank(user1);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT);
        lotterySystem.stake(1, STAKE_AMOUNT);
        vm.stopPrank();

        vm.warp(block.timestamp + STAKING_DURATION + 1);

        // Finalize staking
        lotterySystem.finalizeStaking(1);

        // Try to take winnings before deadline
        vm.startPrank(user1);
        vm.expectRevert("Lottery deadline not passed");
        lotterySystem.takeWinnings(1);
    }

    function test_RevertWhen_TakingWinningsBeforeStakingFinalized() public {
        // Create lottery
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Move time past lottery deadline
        vm.warp(block.timestamp + LOTTERY_DURATION + 1);

        // Try to take winnings before staking is finalized
        vm.startPrank(user1);
        vm.expectRevert("Staking not finalized");
        lotterySystem.takeWinnings(1);
    }

    function testAaveIntegration() public {
        // Create lottery
        vm.startPrank(owner);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Get aUSDC token address from Aave pool
        IERC20 aUSDC = IERC20(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c); // aUSDC on mainnet

        // Record initial balances
        uint256 initialATokenBalance = aUSDC.balanceOf(address(lotterySystem));
        uint256 initialLotteryBalance = usdc.balanceOf(address(lotterySystem));

        console2.log("Initial balances:");
        console2.log("Lottery aToken:", initialATokenBalance);
        console2.log("Lottery USDC:", initialLotteryBalance);

        // Stake
        vm.startPrank(user1);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT);
        lotterySystem.stake(1, STAKE_AMOUNT);
        vm.stopPrank();

        console2.log("\nAfter user stake balances:");
        console2.log("Lottery USDC:", usdc.balanceOf(address(lotterySystem)));
        console2.log("Lottery aToken:", aUSDC.balanceOf(address(lotterySystem)));
        console2.log("Lottery contract address:", address(lotterySystem));

        // Verify stake was successful
        assertEq(
            usdc.balanceOf(address(lotterySystem)),
            initialLotteryBalance + STAKE_AMOUNT,
            "Stake should increase lottery balance"
        );

        // Move time past staking deadline
        vm.warp(block.timestamp + STAKING_DURATION + 1);

        // Finalize staking
        lotterySystem.finalizeStaking(1);

        // Move time forward to accumulate some yield
        vm.warp(block.timestamp + 1 days);

        // Get final balances
        uint256 finalATokenBalance = aUSDC.balanceOf(address(lotterySystem));
        uint256 finalLotteryBalance = usdc.balanceOf(address(lotterySystem));

        console2.log("\nFinal balances:");
        console2.log("Lottery aToken:", finalATokenBalance);
        console2.log("Lottery USDC:", finalLotteryBalance);

        // Verify aToken balance increased (this means supply was successful)
        assertTrue(finalATokenBalance > 0, "aToken balance should be greater than 0");

        // Verify USDC was transferred from lottery to pool
        assertEq(finalLotteryBalance, 0, "Lottery should have 0 USDC after supply");
    }
}
