# Deployment Instructions

This guide will help you deploy the VotingSystem contracts to the Sepolia testnet.

## Prerequisites

1. Install Foundry: https://book.getfoundry.sh/getting-started/installation
2. Get some Sepolia ETH from a faucet: https://sepoliafaucet.com/

## Contract Addresses

The contracts are already deployed on Sepolia testnet:

- **VegaVote Token**: 0xD3835FE9807DAecc7dEBC53795E7170844684CeF
- **VotingResultNFT**: 0xe71727Cdc8479d82cB71E774a3fFBB8742CC44af
- **VotingSystem**: 0xbbC5Cb2a800E25be71bbc90669b6802C60D1628e

## Deploy Your Own Contracts (Optional)

If you want to deploy your own contracts:

1. Clone the repository and navigate to the project folder

2. Create a `.env` file with your private key:
   ```
   PRIVATE_KEY=your_private_key_here
   ```

3. Run the deployment script:
   ```bash
   forge script script/Deploy.s.sol:DeployScript --rpc-url https://sepolia.infura.io/v3/8b4535c511eb4b8fb625279437c92ed2 --private-key 0x$PRIVATE_KEY --broadcast --legacy
   ```

4. The script will output the addresses of your deployed contracts. Save these addresses for future reference.

## Interacting with the Contracts

### Create a Vote (Admin Only)

```bash
cast send 0xbbC5Cb2a800E25be71bbc90669b6802C60D1628e "createVote(string,uint256,uint256)" "Should we implement feature X?" 604800 1000000000000000000 --private-key 0x$PRIVATE_KEY --rpc-url https://sepolia.infura.io/v3/8b4535c511eb4b8fb625279437c92ed2 --legacy
```

This creates a vote with:
- Description: "Should we implement feature X?"
- Duration: 7 days (604800 seconds)
- Threshold: 1 token (1e18 wei)

### Stake Tokens for Voting Power

```bash
cast send 0xD3835FE9807DAecc7dEBC53795E7170844684CeF "stake(uint256,uint256)" 1000000000000000000 31536000 --private-key 0x$PRIVATE_KEY --rpc-url https://sepolia.infura.io/v3/8b4535c511eb4b8fb625279437c92ed2 --legacy
```

This stakes 1 token for 1 year (31536000 seconds).

### Cast a Vote

```bash
cast send 0xbbC5Cb2a800E25be71bbc90669b6802C60D1628e "castVote(uint256,bool)" 1 true --private-key 0x$PRIVATE_KEY --rpc-url https://sepolia.infura.io/v3/8b4535c511eb4b8fb625279437c92ed2 --legacy
```

This casts a "yes" vote for vote ID 1.

### Finalize a Vote

```bash
cast send 0xbbC5Cb2a800E25be71bbc90669b6802C60D1628e "finalizeVote(uint256)" 1 --private-key 0x$PRIVATE_KEY --rpc-url https://sepolia.infura.io/v3/8b4535c511eb4b8fb625279437c92ed2 --legacy
```

This finalizes vote ID 1 (only works after the deadline has passed). 