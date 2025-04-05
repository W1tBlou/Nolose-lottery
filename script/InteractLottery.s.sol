// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {LotterySystem} from "../src/LotterySystem.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InteractLottery is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the deployed contract address
        address lotteryAddress = 0x4D65Bf06b4F49Ce8a14aBF09c7D2ECe9fd6E220D;
        LotterySystem lottery = LotterySystem(lotteryAddress);

        // Get USDC address from env
        address usdcAddress = vm.envAddress("SEPOLIA_USDC_ADDRESS");
        IERC20 usdc = IERC20(usdcAddress);

        // Create a lottery with 1 minute staking duration and 3 minutes total duration
        lottery.createLottery(180, 60); // 3 minutes total, 1 minute staking
        console2.log("Lottery created with ID: 1");

        // Approve USDC spending
        uint256 amount = 100 * 10 ** 6; // 100 USDC (6 decimals)
        require(usdc.approve(lotteryAddress, amount), "USDC approval failed");
        console2.log("Approved 100 USDC for lottery contract");

        // Stake 100 USDC
        lottery.stake(1, amount);
        console2.log("Staked 100 USDC in lottery ID: 1");

        // Get lottery details
        (
            uint256 id,
            uint256 deadline,
            uint256 stakingDeadline,
            bool finalized,
            bool stakingFinalized,
            address winner,
            uint256 randomRequestId,
            uint256 randomNumber,
            uint256 yield,
            address initiator
        ) = lottery.lotteries(1);
        console2.log("Lottery ID: %s", id);
        console2.log("Staking deadline: %s", stakingDeadline);
        console2.log("Total duration ends: %s", deadline);

        vm.stopBroadcast();
    }
}
