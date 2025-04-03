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
        assertEq(requestId, 10); // First requestId should be 10 (counter starts at 10)

        // Check that player1 has been assigned a result
        uint256 result = randomNum.s_results(player1);
        assertEq(result, 42); // (0 % 20) + 1 = 1
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

    function testOnlyOwnerCanRoll() public {
        vm.startPrank(player1);
        vm.expectRevert();
        randomNum.rollDice(player1);
        vm.stopPrank();
    }
}
