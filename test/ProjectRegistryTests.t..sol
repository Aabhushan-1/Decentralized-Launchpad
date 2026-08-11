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

    function test_submitProject_Updates_Mapping() public {
        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );

        uint256 expectedProjectId = 0;

        ProjectRegistry.Project memory _project = projectRegistry.getProject(expectedProjectId);

        assertEq(_project.projectName, _projectName);
        assertEq(_project.projectOwner, address(this));
        assertEq(_project.fundingGoal, _fundingGoal);
        assertEq(uint256(_project.projectStatus), uint256(ProjectRegistry.ProjectStatus.Voting));
        // ProjectRegistry.Project memory expectedProject = ProjectRegistry.Project({
        //     projectId: 0,
        //     projectOwner: address(this),
        //     projectName: _projectName,
        //     projectCategory: _projectCategory,
        //     projectDescription: _projectDescription,
        //     createdAt: block.timestamp,
        //     fundingGoal: _fundingGoal,
        //     projectObjectives: _projectObjectives,
        //     projectReturnType: _projectReturnType,
        //     projectStatus: ProjectRegistry.ProjectStatus.Voting
        // });

        // assertEq(abi.encode(_project), abi.encode(expectedProject));
    }

    function test_approveProject_Reverts_If_Not_Owner() public {
        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );

        uint256 expectedProjectId = 0;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        projectRegistry.approveProject(expectedProjectId);
    }
}
