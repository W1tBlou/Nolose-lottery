#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found"
    exit 1
fi

# Function to deploy to Anvil
deploy_anvil() {
    echo "Deploying to Anvil..."
    forge script script/DeployLottery.s.sol:DeployLottery --rpc-url http://localhost:8545 --broadcast
}

# Function to deploy to Sepolia
deploy_sepolia() {
    echo "Deploying to Sepolia..."
    forge script script/DeployLottery.s.sol:DeployLottery --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
}

# Function to interact with contract on Sepolia
interact_sepolia() {
    echo "Interacting with contract on Sepolia..."
    forge script script/InteractWithLottery.s.sol:InteractWithLottery --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
}

# Check command line argument
if [ "$1" = "anvil" ]; then
    deploy_anvil
elif [ "$1" = "sepolia" ]; then
    deploy_sepolia
elif [ "$1" = "interact" ]; then
    interact_sepolia
else
    echo "Usage: ./deploy.sh [anvil|sepolia|interact]"
    exit 1
fi 