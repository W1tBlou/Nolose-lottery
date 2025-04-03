# No-Lose Lottery Experiment

This is an experimental implementation of a no-lose lottery using Chainlink VRF for randomness generation. The contract is deployed on Sepolia testnet.

## Deployed Contract
Contract Address: [0x4D65Bf06b4F49Ce8a14aBF09c7D2ECe9fd6E220D](https://sepolia.etherscan.io/address/0x4D65Bf06b4F49Ce8a14aBF09c7D2ECe9fd6E220D)

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
./deploy.sh sepolia
```

## Interaction

0. Add your smart contract to consumers in [vrf.chain.link](vrf.chain.link) and to new logic upkeep on [automation.chain.link/sepolia](automation.chain.link/sepolia)

1. Create a new lottery and stake 100 USDC:
```bash
PRIVATE_KEY=.... SEPOLIA_USDC_ADDRESS=0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8 forge script script/InteractLottery.s.sol:InteractLottery --rpc-url https://sepolia.infura.io/v3/8b4535c511eb4b8fb625279437c92ed2 --broadcast -vv
```

2. Stake USDC in the lottery:
- Approve USDC spending for the lottery contract
- Call `stake()` with the lottery ID and amount

3. Finalize staking:
- Wait for the staking period to end, it will be done by chainlink 

4. Finalize lottery:
- Wait for the lottery period to end, it will be done by chainlink

## TODO
- [ ] Implement Aave integration for yield generation
- [ ] Add tests for Aave integration
- [ ] Add more documentation about yield calculation
- [ ] Add frontend interface

## Note
Currently, the Aave integration is disabled. The contract works as a basic lottery system with random winner selection via Chainlink VRF, but without yield generation. Future updates will include proper Aave integration for yield generation. 