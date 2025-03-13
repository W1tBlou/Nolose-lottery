// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VotingPowerManager
 * @dev Contract for managing voting power based on staked VegaVote tokens
 */
contract VotingPowerManager is Ownable {
    // VegaVote token contract
    IERC20 public vegaVote;

    uint256 public constant MAX_STAKE_PERIOD = 4 * 365 days;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => Stake[]) public stakes;
    uint256 public totalStaked;

    // Events
    event Staked(address indexed user, uint256 amount, uint256 startTime, uint256 endTime);
    event Unstaked(address indexed user, uint256 stakeIndex, uint256 amount);

    /**
     * @dev Constructor
     * @param _vegaVote Address of the VegaVote token contract
     */
    constructor(address _vegaVote) Ownable(msg.sender) {
        vegaVote = IERC20(_vegaVote);
    }

    /**
     * @dev Stake tokens for voting power
     * @param amount Amount of tokens to stake
     * @param stakePeriod Duration of the stake in seconds
     */
    function stake(uint256 amount, uint256 stakePeriod) external {
        require(amount > 0, "Cannot stake 0 tokens");
        require(stakePeriod <= MAX_STAKE_PERIOD, "Stake period exceeds maximum");
        require(vegaVote.balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Transfer tokens from user to this contract
        require(vegaVote.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + stakePeriod;

        stakes[msg.sender].push(Stake({amount: amount, startTime: startTime, endTime: endTime}));

        totalStaked += amount;

        emit Staked(msg.sender, amount, startTime, endTime);
    }

    /**
     * @dev Unstake tokens after staking period
     * @param stakeIndex Index of the stake to unstake
     */
    function unstake(uint256 stakeIndex) external {
        require(stakeIndex < stakes[msg.sender].length, "Invalid stake index");

        Stake storage userStake = stakes[msg.sender][stakeIndex];
        require(userStake.amount > 0, "No tokens staked");
        require(block.timestamp >= userStake.endTime, "Staking period not ended");

        uint256 amount = userStake.amount;
        userStake.amount = 0;

        require(vegaVote.transfer(msg.sender, amount), "Transfer failed");
        totalStaked -= amount;

        emit Unstaked(msg.sender, stakeIndex, amount);
    }

    /**
     * @dev Calculate voting power for a specific stake
     * @param stakeIndex Index of the stake
     * @param staker Address of the staker
     * @return Voting power
     */
    function calculateVotingPower(uint256 stakeIndex, address staker) public view returns (uint256) {
        require(stakeIndex < stakes[staker].length, "Invalid stake index");

        Stake storage userStake = stakes[staker][stakeIndex];
        if (userStake.amount == 0) {
            return 0;
        }

        // Voting power increases quadratically with stake duration
        uint256 stakePeriodInYears = ((userStake.endTime - userStake.startTime) * 100) / (365 days);
        return (userStake.amount * stakePeriodInYears * stakePeriodInYears) / 10000;
    }

    /**
     * @dev Get total voting power for a user
     * @param staker Address of the staker
     * @return Total voting power
     */
    function getTotalVotingPower(address staker) external view returns (uint256) {
        uint256 totalPower = 0;

        for (uint256 i = 0; i < stakes[staker].length; i++) {
            totalPower += calculateVotingPower(i, staker);
        }

        return totalPower;
    }

    /**
     * @dev Get all stakes for a user
     * @param staker Address of the staker
     * @return Array of stakes
     */
    function getStakes(address staker) external view returns (Stake[] memory) {
        return stakes[staker];
    }

    /**
     * @dev Get number of stakes for a user
     * @param staker Address of the staker
     * @return Number of stakes
     */
    function getStakeCount(address staker) external view returns (uint256) {
        return stakes[staker].length;
    }
}
