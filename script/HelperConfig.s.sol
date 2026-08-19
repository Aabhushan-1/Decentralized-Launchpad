//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        string tokenName;
        string tokenSymbol;
        uint256 tokenCap;
        uint256 tokenInitialSupply;
        uint256 fundingRoundDuration;
    }

    NetworkConfig public activeConfig;

    bool private sepolia = false;
    bool private anvil = false;

    constructor() {
        if (block.chainid == 11155111) {
            activeConfig = NetworkConfig("LaunchPad", "LPT", 1000, 100, 30 days);
        } else {
            activeConfig = NetworkConfig("LaunchPad", "LPT", 1000, 100, 1 minutes);
        }
    }

    function getActiveConfig() public view returns (NetworkConfig memory) {
        return activeConfig;
    }
}
