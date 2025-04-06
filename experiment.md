# No-Lose Lottery Experiment

This is a full report of tests for No-Lose Lottery. We conducted three different experiments to check the correctness of the proposed solution.
You can also repeat all of them to check the correctness. 

*Prerequisites*: working .env file. More details in [README.md](./README.md)

## TESTS on anvil with sepolia fork

Goal: to test mock aave pool, before testing all on sepolia with chainlink

```bash
source .env
forge test --match-path test/LotterySystemMockAave.t.sol -vvv --fork-url $SEPOLIA_RPC_URL
```

Result: successful run in Github Actions.

## TESTS on anvil with mainnet fork

Goal: to test aave implementation with real world fork, mock chainlink

```bash
source .env
forge test --match-path test/LotterySystem.t.sol -vvv --fork-url $ETH_RPC_URL
```

Result: successful run in Github Actions.


## TESTS on Sepolia Network

Goal: test chainlink interaction to run all code successfully, mock aave.

Implementation:

LotterySystem.sol: [0x7f28f6f28ec19f9e20dd42936e81e77fbf05837a](https://sepolia.etherscan.io/address/0x7f28f6f28ec19f9e20dd42936e81e77fbf05837a)

MockAavePool.sol: [0x70cd80ebea05e9c719be0f8d1472c4956588a3e8](https://sepolia.etherscan.io/address/0x70cd80ebea05e9c719be0f8d1472c4956588a3e8)

Step guide:

1. Create a subsription with small deposit on the [Chainlink VRF](https://docs.chain.link/vrf), copy a subscriptionId to the implementation of the [LotterySystem.sol](./src/LotterySystem.sol)

2. Deploy smartcontract ([LotterySystem.sol](./src/LotterySystem.sol) and [MockAavePool.sol](./src/MockAavePool.sol)) to Sepolia ETH network

```bash
source .env
forge script script/LotterySystem.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

3. Get both addresses for LotterySystem and MockAavePool
- Add address of LotterySystem to the consumer for [VRF](https://vrf.chain.link/)
- Create a Custom-logic Upkeep with the address of the LotterySystem in the [Automation Chainlink](https://automation.chain.link/) with small deposit
- Send to MockAavePool some USDCs, because it is mock, not real implementation
- Update LotterySystem address in the [InteractLottery.s.sol](./script/InteractLottery.s.sol)

4. Start Lottery 1 with your duration and stake some USDC tokens.

```bash
source .env
forge script script/InteractLottery.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

5. Wait until end of the lottery and withdrawl your tokens.

```bash
source .env
cast call YOUR_LOTTERY_ADDRESS "lotteries(uint256)" 1 --rpc-url $SEPOLIA_RPC_URL
```


