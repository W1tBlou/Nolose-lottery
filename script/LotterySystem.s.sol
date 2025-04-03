// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {LotterySystem} from "../src/LotterySystem.sol";

contract LotterySystemDeployScript is Script {
    function run() public {
        // Get deployment parameters from environment variables
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address aavePool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
        address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        // Start broadcasting transactions
        vm.startBroadcast(owner);

        // Deploy LotterySystem
        LotterySystem lotterySystem = new LotterySystem(
            usdc,
            aavePool
        );
        console2.log("LotterySystem deployed at:", address(lotterySystem));

        vm.stopBroadcast();

        // Log deployment summary
        console2.log("\nDeployment Summary:");
        console2.log("-------------------");
        console2.log("Network:", block.chainid);
        console2.log("Owner:", owner);
        console2.log("USDC:", usdc);
        console2.log("Aave Pool:", aavePool);
        console2.log("LotterySystem:", address(lotterySystem));
    }
} 