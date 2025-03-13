// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/VegaVote.sol";

contract DeployTestTokenScript is Script {
    function run() external {
        vm.startBroadcast();

        VegaVote vegaVote = new VegaVote(1_000_000 * 10 ** 18);

        vm.stopBroadcast();

        console.log("VegaVote deployed at:", address(vegaVote));
    }
}
