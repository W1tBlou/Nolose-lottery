// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract MockVRFCoordinator {
    uint256 internal counter = 10;

    function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId) {
        requestId = counter;
        VRFConsumerBaseV2Plus consumer = VRFConsumerBaseV2Plus(msg.sender);
        uint256[] memory randomWords = new uint256[](req.numWords);
        // Generate a number that will result in a valid roll between 1 and 20
        // Since the contract does (randomWords[0] % 20) + 1
        randomWords[0] = 42; // This will result in 1
        consumer.rawFulfillRandomWords(requestId, randomWords);
        counter += 1;
        return requestId;
    }
}
