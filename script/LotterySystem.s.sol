// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {LotterySystem} from "../src/LotterySystem.sol";
import {MockAavePool} from "../src/MockAavePool.sol";

contract LotterySystemDeployScript is Script {
    // Sepolia addresses
    address public constant SEPOLIA_USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address public constant SEPOLIA_VRF_COORDINATOR = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    // 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B

    function run() public {
        // Get deployment parameters from environment variables
        address owner = vm.envAddress("OWNER_ADDRESS");
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        console2.log("Starting deployment with parameters:");
        console2.log("Network: Sepolia");
        console2.log("Owner:", owner);
        console2.log("USDC:", SEPOLIA_USDC);
        console2.log("VRF Coordinator:", SEPOLIA_VRF_COORDINATOR);

        // Start broadcasting transactions
        vm.startBroadcast(privateKey);

        // Deploy MockAavePool
        MockAavePool aavePool = new MockAavePool(SEPOLIA_USDC, SEPOLIA_USDC);
        console2.log("MockAavePool deployed at:", address(aavePool));

        // Deploy LotterySystem
        LotterySystem lotterySystem = new LotterySystem(SEPOLIA_USDC, address(aavePool), SEPOLIA_VRF_COORDINATOR);

        // Verify deployment
        require(address(lotterySystem) != address(0), "Deployment failed");
        require(lotterySystem.lotteryOwner() == owner, "Owner not set correctly");
        require(address(lotterySystem.USDC()) == SEPOLIA_USDC, "USDC not set correctly");
        require(address(lotterySystem.aavePool()) == address(aavePool), "Aave Pool not set correctly");

        console2.log("LotterySystem deployed at:", address(lotterySystem));

        vm.stopBroadcast();

        // Log deployment summary
        console2.log("\nDeployment Summary:");
        console2.log("-------------------");
        console2.log("Network: Sepolia");
        console2.log("Owner:", owner);
        console2.log("USDC:", SEPOLIA_USDC);
        console2.log("VRF Coordinator:", SEPOLIA_VRF_COORDINATOR);
        console2.log("MockAavePool:", address(aavePool));
        console2.log("LotterySystem:", address(lotterySystem));
        console2.log("Deployment successful!");
    }
}
