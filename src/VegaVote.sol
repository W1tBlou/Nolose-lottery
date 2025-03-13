// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VegaVote is ERC20, Ownable {
    uint256 public constant MAX_STAKE_PERIOD = 4 * 365 days;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => Stake[]) public stakes;
    uint256 public totalStaked;

    constructor(uint256 initialSupply) ERC20("VegaVote", "VEGA") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function stake(uint256 amount, uint256 stakePeriod) external {
        require(amount > 0, "Cannot stake 0 tokens");
        require(stakePeriod <= MAX_STAKE_PERIOD, "Stake period exceeds maximum");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _transfer(msg.sender, address(this), amount);

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + stakePeriod;

        stakes[msg.sender].push(Stake({amount: amount, startTime: startTime, endTime: endTime}));

        totalStaked += amount;
    }

    function unstake(uint256 stakeIndex) external {
        require(stakeIndex < stakes[msg.sender].length, "Invalid stake index");

        Stake storage userStake = stakes[msg.sender][stakeIndex];
        require(userStake.amount > 0, "No tokens staked");
        require(block.timestamp >= userStake.endTime, "Staking period not ended");

        uint256 amount = userStake.amount;
        userStake.amount = 0;

        _transfer(address(this), msg.sender, amount);
        totalStaked -= amount;
    }

    function calculateVotingPower(uint256 stakeIndex, address staker) public view returns (uint256) {
        require(stakeIndex < stakes[staker].length, "Invalid stake index");

        Stake storage userStake = stakes[staker][stakeIndex];
        if (userStake.amount == 0) {
            return 0;
        }

        uint256 stakePeriodInYears = ((userStake.endTime - userStake.startTime) * 100) / (365 days);
        return (userStake.amount * stakePeriodInYears * stakePeriodInYears) / 10000;
    }

    function getTotalVotingPower(address staker) external view returns (uint256) {
        uint256 totalPower = 0;

        for (uint256 i = 0; i < stakes[staker].length; i++) {
            totalPower += calculateVotingPower(i, staker);
        }

        return totalPower;
    }

    function getStakes(address staker) external view returns (Stake[] memory) {
        return stakes[staker];
    }

    function getStakeCount(address staker) external view returns (uint256) {
        return stakes[staker].length;
    }
}
