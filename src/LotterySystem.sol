// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LotteryResultNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LotterySystem
 * @dev Contract for managing lotteries using USDC tokens
 */
contract LotterySystem is Ownable, ReentrancyGuard {
    // VegaVote token contract
    IERC20 public USDC;
    IPool public aavePool;

    // LotteryResultNFT contract
    LotteryResultNFT public lotteryResultNFT;

    // Lottery structure
    struct Lottery {
        uint256 id;
        uint256 deadline;
        uint256 stakingDeadline;
        bool finalized;
        bool stakingFinalized;
        address winner;
        address initiator;
    }

    // Mapping from vote ID to Vote
    mapping(uint256 => Lottery) public lotteries;
    
    // Mapping from lottery ID to voter address to stake index
    mapping(uint256 => mapping(address => uint256)) public stakes;
    mapping(uint256 => address[]) public stakers;
    mapping(uint256 => uint256) public totalStakes;

    // Counter for vote IDs
    uint256 private _lotteryIdCounter = 1;

    // Events
    event LotteryCreated(
        uint256 indexed lotteryId, uint256 deadline, uint256 stakingDeadline, address initiator
    );
    event StakeCast(uint256 indexed lotteryId, address indexed staker, uint256 amount);
    event LotteryFinalized(uint256 indexed lotteryId, address winner);
    event LotteryStakingFinalized(uint256 indexed lotteryId, uint256 amount);
    event WinnerSelected(uint256 indexed lotteryId, address winner, uint256 yield);
    event NFTMinted(uint256 indexed lotteryId, uint256 indexed tokenId, address recipient);

    constructor(address _USDC, address _pool, address _lotteryResultNFT) Ownable(msg.sender) {
        USDC = IERC20(_USDC);
        aavePool = IPool(_pool);
        lotteryResultNFT = LotteryResultNFT(_lotteryResultNFT);
    }

    function createLottery(uint256 durationInSeconds, uint256 stakingDurationInSeconds) external onlyOwner {
        require(durationInSeconds > 0, "Duration must be greater than 0");
        require(stakingDurationInSeconds > 0, "Staking duration must be greater than 0");

        uint256 lotteryId = _lotteryIdCounter++;

        lotteries[lotteryId] = Lottery({
            id: lotteryId,
            deadline: block.timestamp + stakingDurationInSeconds + durationInSeconds,
            stakingDeadline: block.timestamp + stakingDurationInSeconds,
            finalized: false,
            stakingFinalized: false,
            winner: address(0),
            initiator: msg.sender
        });

        emit LotteryCreated(lotteryId, block.timestamp + stakingDurationInSeconds + durationInSeconds, block.timestamp + stakingDurationInSeconds, msg.sender);
    }

    function stake(uint256 lotteryId, uint256 amount) external {
        //сюда можно добавить проверку закончился ли стакинг или нет
        Lottery storage lottery = lotteries[lotteryId];
        
        require(lottery.id != 0, "Lottery does not exist");
        require(!lottery.stakingFinalized, "Lottery staking period has ended");
        require(block.timestamp < lottery.stakingDeadline, "Staking deadline passed");
        require(amount > 0, "Amount must be greater than 0");
        require(USDC.balanceOf(msg.sender) >= amount, "Insufficient USDC balance");
        
        // Transfer USDC from user to contract
        require(USDC.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");
        
        // Record the stake
        if (stakes[lotteryId][msg.sender] == 0) {
            stakers[lotteryId].push(msg.sender);
        }
        stakes[lotteryId][msg.sender] += amount;
        totalStakes[lotteryId] += amount;
        
        emit StakeCast(lotteryId, msg.sender, amount);
    }

    function finalizeStaking(uint256 lotteryId) external nonReentrant {
        Lottery storage lottery = lotteries[lotteryId];
        uint256 amount = totalStakes[lotteryId];

        require(lottery.id != 0, "Lottery does not exist");
        require(!lottery.stakingFinalized, "Lottery staking already finalized");
        require(block.timestamp >= lottery.stakingDeadline, "Lottery staking deadline not passed");
    
        lottery.stakingFinalized = true;
        
        // Approve USDC spending for Aave pool
        require(USDC.approve(address(aavePool), amount), "USDC approval failed");
        
        // Supply USDC to Aave pool
        try aavePool.supply(address(USDC), amount, address(this), 0) {
            // Successfully supplied to Aave
        } catch {
            // If Aave supply fails, revert the transaction
            revert("Failed to supply USDC to Aave pool");
        }

        emit LotteryStakingFinalized(lotteryId, amount);
    }

    function finalizeLottery(uint256 lotteryId) external nonReentrant {
        Lottery storage lottery = lotteries[lotteryId];

        require(lottery.id != 0, "Lottery does not exist");
        require(!lottery.finalized, "Lottery already finalized");
        require(block.timestamp >= lottery.deadline, "Lottery deadline not passed");

        require(lottery.stakingFinalized, "Staking not finalized");
        
        // Withdraw all USDC + yield from Aave
        uint256 amountWithYield = USDC.balanceOf(address(aavePool));
        try aavePool.withdraw(address(USDC), amountWithYield, address(this)) {
            // Successfully withdrawn from Aave
        } catch {
            revert("Failed to withdraw from Aave pool");
        }

        uint256 originalStake = totalStakes[lotteryId];
        uint256 yield = amountWithYield - originalStake;

        // Iterate through stakes to find winner based on weighted random selection
        address[] memory stakersList = stakers[lotteryId];
        
        // Select random winner
        uint256 randomValue = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            block.timestamp,
            msg.sender
        )));
        
        // Scale down to range [0,1] by dividing by max uint256
        uint256 scaledRandom = randomValue / type(uint256).max;
        
        uint256 cumulativeStake = 0;
        address winner;

        // Iterate through stakes to find winner based on weighted random selection
        for (uint256 i = 0; i < stakersList.length; i++) {
            address staker = stakersList[i];
            cumulativeStake += stakes[lotteryId][staker] / totalStakes[lotteryId];
            if (cumulativeStake > scaledRandom && winner == address(0)) {
                winner = staker;
                break;
            }
        }
        
        lottery.winner = winner;

        // Return original stakes to all participants
        for (uint256 i = 0; i < stakersList.length; i++) {
            address staker = stakersList[i];
            uint256 userStake = stakes[lotteryId][staker];
            if (userStake > 0) {
                require(USDC.transfer(staker, userStake), "USDC transfer failed");
            }
        }

        // Send yield to winner
        require(USDC.transfer(winner, yield), "Failed to transfer yield to winner");

        emit WinnerSelected(lotteryId, winner, yield);

        _finalizeLottery(lotteryId, winner, yield);
    }

    
    function _finalizeLottery(uint256 lotteryId, address winner, uint256 yield) internal nonReentrant {
        Lottery storage lottery = lotteries[lotteryId];

        lottery.finalized = true;

        emit LotteryFinalized(lotteryId, lottery.initiator);

        // Mint NFT for the vote result
            uint256 tokenId = lotteryResultNFT.mintLotteryResult(
            lotteryId, lottery.winner, yield
        );

        emit NFTMinted(lotteryId, tokenId, lottery.winner);
    }

    function isLotteryActive(uint256 lotteryId) external view returns (bool) {
        Lottery storage lottery = lotteries[lotteryId];
        return lottery.id != 0 && !lottery.finalized && block.timestamp < lottery.deadline;
    }

    /**
     * @dev Get the number of votes created
     * @return Number of votes
     */
    function getLotteryCount() external view returns (uint256) {
        return _lotteryIdCounter - 1;
    }
}
