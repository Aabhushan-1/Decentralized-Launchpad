//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ProjectRegistry} from "../src/ProjectRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ProjectRegistryTests is Test {
    ProjectRegistry projectRegistry;
    address owner = makeAddr("owner");

    string _projectName = "NepalTech";
    string _projectCategory = "Technology";
    string _projectDescription = "A platform for Nepali developers to showcase their projects";
    uint256 _fundingGoal = 50000;
    string _projectObjectives = "Build MVP, onboard 100 developers, launch beta";
    ProjectRegistry.ProjectReturnType _projectReturnType = ProjectRegistry.ProjectReturnType.Nothing;

    event ProjectSubmitted(uint256 indexed projectId);
    event ProjectApproved(uint256 indexed projectId);
    event ProjectRejected(uint256 indexed projectId);

    function setUp() public {
        projectRegistry = new ProjectRegistry(owner);
    }

    function test_submitProject() public {
        uint256 expectedProjectId = 0;

        vm.expectEmit();
        emit ProjectSubmitted(expectedProjectId);

        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );
    }
}
