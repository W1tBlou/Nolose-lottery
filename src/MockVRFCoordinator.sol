// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract MockVRFCoordinator {
    uint256 internal counter = 0;
    mapping(uint256 => address) internal s_consumers;
    mapping(uint256 => uint256[]) internal s_randomWords;

    function requestRandomWords(
        VRFV2PlusClient.RandomWordsRequest calldata req
    ) external returns (uint256 requestId) {
        requestId = counter;
        s_consumers[requestId] = msg.sender;
        
        // Generate deterministic but seemingly random numbers
        uint256[] memory randomWords = new uint256[](req.numWords);
        for (uint256 i = 0; i < req.numWords; i++) {
            randomWords[i] = uint256(
                keccak256(
                    abi.encodePacked(
                        counter,
                        block.timestamp,
                        block.prevrandao,
                        i
                    )
                )
            );
        }
        s_randomWords[requestId] = randomWords;
        counter += 1;
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId) external {
        require(s_consumers[requestId] != address(0), "Request not found");
        VRFConsumerBaseV2Plus consumer = VRFConsumerBaseV2Plus(s_consumers[requestId]);
        consumer.rawFulfillRandomWords(requestId, s_randomWords[requestId]);
        delete s_consumers[requestId];
        delete s_randomWords[requestId];
    }
} 