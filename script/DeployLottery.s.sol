// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {LotterySystem} from "../src/LotterySystem.sol";

contract DeployLottery is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get contract addresses from environment
        address usdcAddress = vm.envAddress("SEPOLIA_USDC_ADDRESS");
        address aavePoolAddress = vm.envAddress("SEPOLIA_AAVE_POOL_ADDRESS");

        // Deploy LotterySystem
        LotterySystem lottery = new LotterySystem(usdcAddress, aavePoolAddress);
        console2.log("LotterySystem deployed to Sepolia at:", address(lottery));

        vm.stopBroadcast();
    }
}
