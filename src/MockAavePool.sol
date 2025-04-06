// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockAavePool {
    // Mock USDC token
    IERC20 public usdc;
    // Mock yield rate (0.1% per day)
    uint256 public constant YIELD_RATE = 1000; // 0.1% = 1000 / 1000000

    // Mapping to track supplied amounts
    mapping(address => uint256) public suppliedAmounts;

    constructor(address _usdc, address) {
        usdc = IERC20(_usdc);
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 /* referralCode */ )
        external
        returns (bool)
    {
        require(asset == address(usdc), "Only USDC supported");
        require(amount > 0, "Amount must be greater than 0");

        // Transfer USDC from caller to this contract
        require(usdc.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Record supplied amount
        suppliedAmounts[onBehalfOf] += amount;

        return true;
    }

    function withdraw(address asset, uint256, /* amount */ address to) external returns (bool) {
        require(asset == address(usdc), "Only USDC supported");

        uint256 supplied = suppliedAmounts[msg.sender];
        require(supplied > 0, "No supplied amount");

        // Calculate yield
        uint256 yield = (supplied * YIELD_RATE) / 1000000;
        uint256 totalAmount = supplied + yield;

        // Reset supplied amount before transfer to prevent reentrancy
        suppliedAmounts[msg.sender] = 0;

        // Ensure we have enough USDC to cover the withdrawal + yield
        require(usdc.balanceOf(address(this)) >= totalAmount, "Insufficient pool balance");

        // Transfer USDC + yield to recipient
        require(usdc.transfer(to, totalAmount), "Withdraw failed");

        return true;
    }
}
