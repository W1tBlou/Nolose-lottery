// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./VotingPowerManager.sol";
import "./VotingResultNFT.sol";

/**
 * @title VotingSystem
 * @dev Contract for managing votes using VegaVote tokens
 */
contract VotingSystem is Ownable {
    // VegaVote token contract
    IERC20 public vegaVote;

    // VotingPowerManager contract
    VotingPowerManager public votingPowerManager;

    // VotingResultNFT contract
    VotingResultNFT public votingResultNFT;

    // Vote structure
    struct Vote {
        uint256 id;
        string description;
        uint256 deadline;
        uint256 threshold;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool passed;
        address initiator;
    }

    // Mapping from vote ID to Vote
    mapping(uint256 => Vote) public votes;

    // Mapping from vote ID to voter address to whether they have voted
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Counter for vote IDs
    uint256 private _voteIdCounter = 1;

    // Events
    event VoteCreated(
        uint256 indexed voteId, string description, uint256 deadline, uint256 threshold, address initiator
    );
    event VoteCast(uint256 indexed voteId, address indexed voter, bool support, uint256 votingPower);
    event VoteFinalized(uint256 indexed voteId, bool passed, uint256 yesVotes, uint256 noVotes);
    event NFTMinted(uint256 indexed voteId, uint256 indexed tokenId, address recipient);

    /**
     * @dev Constructor
     * @param _vegaVote Address of the VegaVote token contract
     * @param _votingPowerManager Address of the VotingPowerManager contract
     * @param _votingResultNFT Address of the VotingResultNFT contract
     */
    constructor(address _vegaVote, address _votingPowerManager, address _votingResultNFT) Ownable(msg.sender) {
        vegaVote = IERC20(_vegaVote);
        votingPowerManager = VotingPowerManager(_votingPowerManager);
        votingResultNFT = VotingResultNFT(_votingResultNFT);
    }

    /**
     * @dev Create a new vote
     * @param description Description of the vote
     * @param durationInSeconds Duration of the vote in seconds
     * @param threshold Threshold of yes votes required for the vote to pass
     */
    function createVote(string memory description, uint256 durationInSeconds, uint256 threshold) external onlyOwner {
        require(durationInSeconds > 0, "Duration must be greater than 0");
        require(threshold > 0, "Threshold must be greater than 0");

        uint256 voteId = _voteIdCounter++;

        votes[voteId] = Vote({
            id: voteId,
            description: description,
            deadline: block.timestamp + durationInSeconds,
            threshold: threshold,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            passed: false,
            initiator: msg.sender
        });

        emit VoteCreated(voteId, description, block.timestamp + durationInSeconds, threshold, msg.sender);
    }

    /**
     * @dev Cast a vote
     * @param voteId ID of the vote
     * @param support Whether to vote yes (true) or no (false)
     */
    function castVote(uint256 voteId, bool support) external {
        Vote storage vote = votes[voteId];

        require(vote.id != 0, "Vote does not exist");
        require(!vote.finalized, "Vote already finalized");
        require(block.timestamp < vote.deadline, "Vote deadline passed");
        require(!hasVoted[voteId][msg.sender], "Already voted");

        // Calculate voting power
        uint256 votingPower = votingPowerManager.getTotalVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");

        // Record the vote
        if (support) {
            vote.yesVotes += votingPower;
        } else {
            vote.noVotes += votingPower;
        }

        hasVoted[voteId][msg.sender] = true;

        emit VoteCast(voteId, msg.sender, support, votingPower);

        // Check if threshold is met
        if (vote.yesVotes >= vote.threshold) {
            _finalizeVote(voteId, true);
        }
    }

    /**
     * @dev Finalize a vote after deadline
     * @param voteId ID of the vote
     */
    function finalizeVote(uint256 voteId) external {
        Vote storage vote = votes[voteId];

        require(vote.id != 0, "Vote does not exist");
        require(!vote.finalized, "Vote already finalized");
        require(block.timestamp >= vote.deadline, "Vote deadline not passed");

        bool passed = vote.yesVotes > vote.noVotes;
        _finalizeVote(voteId, passed);
    }

    /**
     * @dev Internal function to finalize a vote
     * @param voteId ID of the vote
     * @param passed Whether the vote passed
     */
    function _finalizeVote(uint256 voteId, bool passed) internal {
        Vote storage vote = votes[voteId];

        vote.finalized = true;
        vote.passed = passed;

        emit VoteFinalized(voteId, passed, vote.yesVotes, vote.noVotes);

        // Mint NFT for the vote result
        uint256 tokenId = votingResultNFT.mintVoteResult(
            voteId, vote.description, vote.yesVotes, vote.noVotes, passed, vote.initiator
        );

        emit NFTMinted(voteId, tokenId, vote.initiator);
    }

    /**
     * @dev Get vote details
     * @param voteId ID of the vote
     * @return Vote details
     */
    function getVote(uint256 voteId) external view returns (Vote memory) {
        require(votes[voteId].id != 0, "Vote does not exist");
        return votes[voteId];
    }

    /**
     * @dev Check if a vote is active
     * @param voteId ID of the vote
     * @return Whether the vote is active
     */
    function isVoteActive(uint256 voteId) external view returns (bool) {
        Vote storage vote = votes[voteId];
        return vote.id != 0 && !vote.finalized && block.timestamp < vote.deadline;
    }

    /**
     * @dev Get the number of votes created
     * @return Number of votes
     */
    function getVoteCount() external view returns (uint256) {
        return _voteIdCounter - 1;
    }
}
