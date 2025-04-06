// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {LotterySystem} from "../src/LotterySystem.sol";
import {MyVRFCoordinatorV2Mock} from "../src/MockVRFCoordinator.sol";
import {MockAavePool} from "../src/MockAavePool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LotterySystemMockAaveTest is Test {
    LotterySystem public lotterySystem;
    IERC20 public usdc;
    MockAavePool public aavePool;
    MyVRFCoordinatorV2Mock public mockCoordinator;

    // Sepolia USDC address
    address public constant SEPOLIA_USDC_ADDRESS = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    // Your owner address
    address public constant OWNER_ADDRESS = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;
    // Test users
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");

    uint256 public constant INITIAL_BALANCE = 10 * 10 ** 6; // 10 USDC (6 decimals)
    uint256 public constant STAKE_AMOUNT = 1 * 10 ** 6; // 1 USDC
    uint256 public constant LOTTERY_DURATION = 1 days;
    uint256 public constant STAKING_DURATION = 1 hours;

    function setUp() public {
        // Get real USDC token
        usdc = IERC20(SEPOLIA_USDC_ADDRESS);

        // Deal USDC to owner
        deal(address(usdc), OWNER_ADDRESS, INITIAL_BALANCE * 10);

        // Check owner's USDC balance
        uint256 ownerBalance = usdc.balanceOf(OWNER_ADDRESS);
        console2.log("Owner USDC balance:", ownerBalance);
        require(ownerBalance >= INITIAL_BALANCE * 4, "Owner does not have enough USDC for testing");

        // Deploy mock contracts
        mockCoordinator = new MyVRFCoordinatorV2Mock();
        aavePool = new MockAavePool(address(usdc), address(usdc)); // Using USDC as aToken for simplicity

        // Deploy lottery system
        vm.startPrank(OWNER_ADDRESS);
        lotterySystem = new LotterySystem(address(usdc), address(aavePool), address(mockCoordinator));
        vm.stopPrank();

        // Setup test users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);

        // Transfer USDC to test users and pool
        vm.startPrank(OWNER_ADDRESS);
        usdc.transfer(user1, INITIAL_BALANCE);
        usdc.transfer(user2, INITIAL_BALANCE);
        usdc.transfer(user3, INITIAL_BALANCE);
        usdc.transfer(address(aavePool), INITIAL_BALANCE); // Give pool enough USDC for withdrawals
        vm.stopPrank();
    }

    function testCreateLottery() public {
        vm.startPrank(OWNER_ADDRESS);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        assertEq(lotterySystem.getLotteryCount(), 1);
        assertTrue(lotterySystem.isLotteryActive(1));
    }

    function testStake() public {
        // Create lottery
        vm.startPrank(OWNER_ADDRESS);
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
        vm.startPrank(OWNER_ADDRESS);
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
        vm.startPrank(OWNER_ADDRESS);
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
        (,,,, bool stakingFinalized,,,,,) = lotterySystem.lotteries(1);
        assertTrue(stakingFinalized);
    }

    function testTakeWinningsAndWinnerSelection() public {
        // Create lottery
        vm.startPrank(OWNER_ADDRESS);
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

        // Fulfill random words
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 42;
        (,,,,,, uint256 randomRequestId,,,) = lotterySystem.lotteries(1);
        lotterySystem.fulfillRandomWords_mock(randomRequestId, randomWords);

        // Move time past lottery deadline
        vm.warp(block.timestamp + LOTTERY_DURATION + 1);

        // Record balances before taking winnings
        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        uint256 user2BalanceBefore = usdc.balanceOf(user2);
        uint256 user3BalanceBefore = usdc.balanceOf(user3);

        lotterySystem.finalizeLottery(1);

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
        (,,, bool finalized,, address winner,,,,) = lotterySystem.lotteries(1);
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
        vm.startPrank(OWNER_ADDRESS);
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
        vm.startPrank(OWNER_ADDRESS);
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
        vm.startPrank(OWNER_ADDRESS);
        lotterySystem.createLottery(LOTTERY_DURATION, STAKING_DURATION);
        vm.stopPrank();

        // Record initial balances
        uint256 initialLotteryBalance = usdc.balanceOf(address(lotterySystem));

        // Stake
        vm.startPrank(user1);
        usdc.approve(address(lotterySystem), STAKE_AMOUNT);
        lotterySystem.stake(1, STAKE_AMOUNT);
        vm.stopPrank();

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
        uint256 finalLotteryBalance = usdc.balanceOf(address(lotterySystem));

        // Verify USDC was transferred from lottery to pool
        assertEq(finalLotteryBalance, 0, "Lottery should have 0 USDC after supply");
    }
}
