// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {LotterySystem} from "../src/LotterySystem.sol";

contract DeployLottery is Script {
    function setUp() public {}

    function run() public {
        // Get private key from environment and ensure it has 0x prefix
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        if (bytes(privateKeyStr)[0] != "0") {
            privateKeyStr = string(abi.encodePacked("0x", privateKeyStr));
        }
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
        
        vm.startBroadcast(deployerPrivateKey);

        // Get addresses from environment variables
        address usdcAddress = vm.envAddress("SEPOLIA_USDC_ADDRESS");
        address aavePoolAddress = vm.envAddress("SEPOLIA_AAVE_POOL_ADDRESS");

        // Deploy LotterySystem
        LotterySystem lottery = new LotterySystem(usdcAddress, aavePoolAddress);
        console2.log("LotterySystem deployed to:", address(lottery));

        vm.stopBroadcast();
    }
} 