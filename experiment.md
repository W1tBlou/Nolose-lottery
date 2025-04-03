# No-Lose Lottery Experiment

This is an experimental implementation of a no-lose lottery using Chainlink VRF for randomness generation. The contract is deployed on Sepolia testnet.

## Deployed Contract
Contract Address: [0x7a8486eBdD87F762056C7F4c952A8c71784A50EC](https://sepolia.etherscan.io/address/0x7a8486eBdD87F762056C7F4c952A8c71784A50EC)

## Setup

1. Create a `.env` file with the following variables:
```
SEPOLIA_RPC_URL=<your-sepolia-rpc-url>
SEPOLIA_USDC_ADDRESS=0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8
SEPOLIA_AAVE_POOL_ADDRESS=0xE7EC1B0015eb2ADEedb1B7f9F1Ce82F9DAD6dF08
PRIVATE_KEY=<your-private-key>
```

## Deployment

To deploy the contract:
```bash
./deploy.sh deploy
```

## Interaction

1. Create a new lottery:
```bash
./deploy.sh interact
```

2. Stake USDC in the lottery:
- Approve USDC spending for the lottery contract
- Call `stake()` with the lottery ID and amount

3. Finalize staking:
- Wait for the staking period to end
- Call `finalizeStaking()`
- Wait for Chainlink VRF to provide random number

4. Finalize lottery:
- Wait for the lottery period to end
- Call `finalizeLottery()`
- Winners will receive their stakes back plus yield

## TODO
- [ ] Implement Aave integration for yield generation
- [ ] Add tests for Aave integration
- [ ] Add more documentation about yield calculation
- [ ] Add frontend interface

## Note
Currently, the Aave integration is disabled. The contract works as a basic lottery system with random winner selection via Chainlink VRF, but without yield generation. Future updates will include proper Aave integration for yield generation. 