// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {LotterySystem} from "../src/LotterySystem.sol";

contract LotterySystemDeployScript is Script {
    function run() public {
        // Get deployment parameters from environment variables
        address usdc = vm.envAddress("USDC_ADDRESS");
        address aavePool = vm.envAddress("AAVE_POOL_ADDRESS");
        address owner = vm.envAddress("OWNER_ADDRESS");

        console2.log("Starting deployment with parameters:");
        console2.log("USDC:", usdc);
        console2.log("Aave Pool:", aavePool);
        console2.log("Owner:", owner);

        // Start broadcasting transactions
        vm.startBroadcast(owner);

        // Deploy LotterySystem
        LotterySystem lotterySystem = new LotterySystem(
            usdc,
            aavePool
        );

        // Verify deployment
        require(address(lotterySystem) != address(0), "Deployment failed");
        require(lotterySystem.owner() == owner, "Owner not set correctly");
        require(address(lotterySystem.USDC()) == usdc, "USDC not set correctly");
        require(address(lotterySystem.aavePool()) == aavePool, "Aave Pool not set correctly");

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
        console2.log("Deployment successful!");
    }
}