// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {LotterySystem} from "../src/LotterySystem.sol";

contract FinalizeStaking is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the deployed contract address
        address lotteryAddress = 0x0f445E2E6A47b35914Cb54328d56e7fC785E0a99;
        LotterySystem lottery = LotterySystem(lotteryAddress);

        // Finalize staking for lottery ID 1
        lottery.finalizeStaking(1);
        console2.log("Staking finalized for lottery ID: 1");
        console2.log("Total stakes: %s", lottery.totalStakes(1));

        vm.stopBroadcast();
    }
}
