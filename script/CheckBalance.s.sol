// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CheckBalance is Script {
    function setUp() public {}

    function run() public {
        // Get USDC address from env
        address usdcAddress = vm.envAddress("SEPOLIA_USDC_ADDRESS");
        IERC20 usdc = IERC20(usdcAddress);

        // Get deployer address
        address deployer = vm.envAddress("OWNER_ADDRESS");

        // Check USDC balance
        uint256 balance = usdc.balanceOf(deployer);
        console2.log("USDC Balance: %s", balance);
        console2.log("USDC Balance in USDC: %s", balance / 10 ** 6);
    }
}
