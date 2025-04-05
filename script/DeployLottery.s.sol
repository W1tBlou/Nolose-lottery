// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {LotterySystem} from "../src/LotterySystem.sol";

contract DeployLottery is Script {
    function setUp() public {}

    function run() public {
        // Use vm.envString instead of vm.envUint for the private key
        string memory privateKeyString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(privateKeyString);
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
