# VegaVote Voting System

A simple voting system using the VegaVote token for quadratic voting power.

## Overview

This project implements a voting system where:

1. Users stake VegaVote tokens for a duration between 0 and 4 years
2. Voting power is calculated as `stakeAmount * stakePeriod^2`
3. Admin creates votes with a deadline and threshold
4. Users cast votes (yes/no) using their voting power
5. When a vote concludes, an NFT is minted with the results

## Contracts

- **VegaVote**: ERC20 token with staking functionality (using existing token at 0xD3835FE9807DAecc7dEBC53795E7170844684CeF)
- **VotingSystem**: Manages the voting process
- **VotingResultNFT**: Represents voting results as NFTs

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for instructions on how to deploy and interact with the contracts.

## Development

This homework was made with wide support of the cursor.sh app and code Agents.
