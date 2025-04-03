#!/bin/bash

# Load environment variables
source .env

# Deploy the contract to Sepolia
forge script script/DeployRandomNum.s.sol:DeployRandomNum --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

# Function to deploy to Anvil
deploy_anvil() {
    echo "Deploying to Anvil..."
    forge script script/DeployRandomNum.s.sol:DeployRandomNum --rpc-url http://localhost:8545 --broadcast
}

# Function to deploy to Sepolia
deploy_sepolia() {
    echo "Deploying to Sepolia..."
    forge script script/DeployRandomNum.s.sol:DeployRandomNum --rpc-url $SEPOLIA_RPC_URL --broadcast
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