//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Governance} from "../src/Governance.sol";
import {ProjectRegistry} from "../src/ProjectRegistry.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract GovernanceTests is Test {
    Governance governance;
    ProjectRegistry projectRegistry;

    string _projectName = "SolarGrid AI";
    string _projectCategory = "Renewable Energy";
    string _projectDescription = "Decentralized micro-grid monitoring using smart contracts.";
    uint256 _fundingGoal = 100000;
    string _projectObjectives = "Deploy 50 solar nodes, complete IoT integration, launch beta.";
    ProjectRegistry.ProjectReturnType _projectReturnType = ProjectRegistry.ProjectReturnType.Payback;

    function setUp() public {
        projectRegistry = new ProjectRegistry(address(this));
        governance = new Governance(address(projectRegistry));

        projectRegistry.transferOwnership(address(governance));
    }

    modifier project() {
        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );

        _;
    }
}
