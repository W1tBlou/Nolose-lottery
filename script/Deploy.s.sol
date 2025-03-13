// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/VotingPowerManager.sol";
import "../src/VotingResultNFT.sol";
import "../src/VotingSystem.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        address vegaVoteAddress = 0xD3835FE9807DAecc7dEBC53795E7170844684CeF;

        // Deploy VotingPowerManager
        VotingPowerManager votingPowerManager = new VotingPowerManager(vegaVoteAddress);

        // Deploy VotingResultNFT
        VotingResultNFT votingResultNFT = new VotingResultNFT();

        // Deploy VotingSystem
        VotingSystem votingSystem =
            new VotingSystem(vegaVoteAddress, address(votingPowerManager), address(votingResultNFT));

        // Set up VotingResultNFT
        votingResultNFT.setVotingSystem(address(votingSystem));
        votingResultNFT.transferOwnership(address(votingSystem));

        // Transfer ownership of VotingPowerManager to VotingSystem
        votingPowerManager.transferOwnership(address(votingSystem));

        vm.stopBroadcast();

        console.log("Using VegaVote at:", vegaVoteAddress);
        console.log("VotingPowerManager deployed at:", address(votingPowerManager));
        console.log("VotingResultNFT deployed at:", address(votingResultNFT));
        console.log("VotingSystem deployed at:", address(votingSystem));
    }
}
