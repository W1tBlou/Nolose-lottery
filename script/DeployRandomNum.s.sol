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

        // Check if we're deploying to Anvil (local) or Sepolia
        bool isAnvil = block.chainid == 31337;

        if (isAnvil) {
            // Deploy mock coordinator first for Anvil
            MockVRFCoordinator mockCoordinator = new MockVRFCoordinator();
            console2.log("MockVRFCoordinator deployed to:", address(mockCoordinator));

            // Deploy RandomNum with mock coordinator address
            RandomNum randomNum = new RandomNum(1, address(mockCoordinator));
            console2.log("RandomNum deployed to:", address(randomNum));
        } else {
            // Sepolia deployment
            address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
            // Using the correct subscription ID
            uint256 subscriptionId = 26855092016204205124453749677461341788139777924168207765380961489454212986163;
            
            // Deploy RandomNum with Sepolia VRF coordinator
            RandomNum randomNum = new RandomNum(subscriptionId, vrfCoordinator);
            console2.log("RandomNum deployed to Sepolia at:", address(randomNum));
        }

        vm.stopBroadcast();
    }
} 