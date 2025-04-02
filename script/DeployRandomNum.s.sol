// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {RandomNum} from "../src/RandomNum.sol";
import {MockVRFCoordinator} from "../src/MockVRFCoordinator.sol";

contract DeployRandomNum is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock coordinator first
        MockVRFCoordinator mockCoordinator = new MockVRFCoordinator();
        console2.log("MockVRFCoordinator deployed to:", address(mockCoordinator));

        // Deploy RandomNum with mock coordinator address
        RandomNum randomNum = new RandomNum(1, address(mockCoordinator));
        console2.log("RandomNum deployed to:", address(randomNum));

        vm.stopBroadcast();
    }
} 