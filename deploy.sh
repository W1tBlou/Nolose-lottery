#!/bin/bash

# Load environment variables
source .env

# Check if PRIVATE_KEY is set
if [ -z "$PRIVATE_KEY" ]; then
  echo "Error: PRIVATE_KEY is not set in .env file"
  exit 1
fi

# Add 0x prefix to PRIVATE_KEY if it doesn't have it
# if [[ ! "$PRIVATE_KEY" =~ ^0x ]]; then
#   PRIVATE_KEY="0x$PRIVATE_KEY"
#   echo "Added 0x prefix to PRIVATE_KEY"
# fi

# Export the modified PRIVATE_KEY
export PRIVATE_KEY

# Deploy to Sepolia
echo "Deploying to Sepolia..."
forge script script/DeployLottery.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

echo "Deployment complete!"

# Function to deploy to Anvil
deploy_anvil() {
    echo "Deploying to Anvil..."
    forge script script/DeployRandomNum.s.sol:DeployRandomNum --rpc-url http://localhost:8545 --broadcast
}

# Function to deploy to Sepolia
deploy_sepolia() {
    echo "Deploying to Sepolia..."
    # forge script script/ --rpc-url $SEPOLIA_RPC_URL --broadcast
}

# Check command line argument
if [ "$1" = "anvil" ]; then
    deploy_anvil
elif [ "$1" = "sepolia" ]; then
    deploy_sepolia
else
    echo "Usage: ./deploy.sh [anvil|sepolia]"
    exit 1
fi 