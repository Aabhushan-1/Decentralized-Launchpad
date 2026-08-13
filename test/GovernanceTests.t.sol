//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Governance} from "../src/Governance.sol";
import {ProjectRegistry} from "../src/ProjectRegistry.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract GovernanceTests is Test {
    Governance governance;
    ProjectRegistry projectRegistry;

    function setUp() public {
        governance = new Governance(address(projectRegistry));
    }
}
