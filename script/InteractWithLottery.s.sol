// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {LotterySystem} from "../src/LotterySystem.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InteractWithLottery is Script {
    function setUp() public {}

    function run() public {
        // Get private key from environment and ensure it has 0x prefix
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        if (bytes(privateKeyStr)[0] != "0") {
            privateKeyStr = string(abi.encodePacked("0x", privateKeyStr));
        }
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
        
        vm.startBroadcast(deployerPrivateKey);

        // Get contract address
        address lotteryAddress = 0x7a8486eBdD87F762056C7F4c952A8c71784A50EC;
        LotterySystem lottery = LotterySystem(lotteryAddress);

        // Check lottery status
        uint256 lotteryId = 1;
        (uint256 id, uint256 deadline, uint256 stakingDeadline, bool finalized, bool stakingFinalized, address winner, uint256 randomRequestId, uint256 randomNumber, address initiator) = lottery.lotteries(lotteryId);
        
        console2.log("Lottery Status:");
        console2.log("ID:", id);
        console2.log("Deadline:", deadline);
        console2.log("Staking Deadline:", stakingDeadline);
        console2.log("Finalized:", finalized);
        console2.log("Staking Finalized:", stakingFinalized);
        console2.log("Winner:", winner);
        console2.log("Random Request ID:", randomRequestId);
        console2.log("Random Number:", randomNumber);
        console2.log("Initiator:", initiator);

        vm.stopBroadcast();
    }
} 