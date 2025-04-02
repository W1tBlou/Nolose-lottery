// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {RandomNum} from "../src/RandomNum.sol";
import {MockVRFCoordinator} from "../src/MockVRFCoordinator.sol";

contract RandomNumTest is Test {
    RandomNum public randomNum;
    MockVRFCoordinator public mockCoordinator;
    address public owner;
    address public player1;
    address public player2;

    function setUp() public {
        owner = address(this);
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");

        // Deploy mock coordinator
        mockCoordinator = new MockVRFCoordinator();

        // Deploy RandomNum with mock coordinator
        vm.startPrank(owner);
        randomNum = new RandomNum(1, address(mockCoordinator));
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(randomNum.s_subscriptionId(), 1);
        assertEq(randomNum.vrfCoordinator(), address(mockCoordinator));
        assertEq(randomNum.callbackGasLimit(), 40000);
        assertEq(randomNum.requestConfirmations(), 3);
        assertEq(randomNum.numWords(), 1);
    }

    function testRollDice() public {
        vm.startPrank(owner);
        // Roll dice for player1
        uint256 requestId = randomNum.rollDice(player1);
        assertEq(requestId, 0);

        // Check that player1's result is in progress
        assertEq(randomNum.s_results(player1), 42); // ROLL_IN_PROGRESS

        // Fulfill the random words request
        mockCoordinator.fulfillRandomWords(requestId);

        // Check that player1 has been assigned a result (between 1 and 20)
        uint256 result = randomNum.s_results(player1);
        assertTrue(result >= 1 && result <= 20);
        vm.stopPrank();
    }

    function testCannotRollTwice() public {
        vm.startPrank(owner);
        // First roll should succeed
        randomNum.rollDice(player1);

        // Second roll should revert
        vm.expectRevert("Already rolled");
        randomNum.rollDice(player1);
        vm.stopPrank();
    }

    function testHouseAssignment() public {
        vm.startPrank(owner);
        // Roll dice for player1
        uint256 requestId = randomNum.rollDice(player1);

        // Fulfill the random words request
        mockCoordinator.fulfillRandomWords(requestId);

        // Get the house name
        string memory houseName = randomNum.house(player1);
        assertTrue(bytes(houseName).length > 0);
        vm.stopPrank();
    }

    function testCannotGetHouseBeforeRoll() public {
        vm.expectRevert("Dice not rolled");
        randomNum.house(player1);
    }

    function testCannotGetHouseWhileRolling() public {
        vm.startPrank(owner);
        randomNum.rollDice(player1);
        vm.expectRevert("Roll in progress");
        randomNum.house(player1);
        vm.stopPrank();
    }

    function testMultiplePlayers() public {
        vm.startPrank(owner);
        // Roll for player1
        uint256 requestId1 = randomNum.rollDice(player1);
        mockCoordinator.fulfillRandomWords(requestId1);

        // Roll for player2
        uint256 requestId2 = randomNum.rollDice(player2);
        mockCoordinator.fulfillRandomWords(requestId2);

        // Both should have different results
        uint256 result1 = randomNum.s_results(player1);
        uint256 result2 = randomNum.s_results(player2);
        assertTrue(result1 != result2);
        vm.stopPrank();
    }

    function testOnlyOwnerCanRoll() public {
        vm.startPrank(player1);
        vm.expectRevert();
        randomNum.rollDice(player1);
        vm.stopPrank();
    }
} 