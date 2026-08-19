//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ProjectRegistry} from "../src/ProjectRegistry.sol";
import {LaunchpadToken} from "../src/LaunchpadToken.sol";
import {Governance} from "../src/Governance.sol";

contract DeployAll is Script {
    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveConfig();

        vm.startBroadcast();
        ProjectRegistry projectRegistry = new ProjectRegistry(msg.sender);
        new LaunchpadToken(config.tokenName, config.tokenSymbol, config.tokenCap, config.tokenInitialSupply, msg.sender);
        Governance governance = new Governance(address(projectRegistry), config.fundingRoundDuration);
        projectRegistry.transferOwnership(address(governance));
        vm.stopBroadcast();
    }
}
