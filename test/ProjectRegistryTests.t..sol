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
        uint256 _projectId = projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );

        ProjectRegistry.Project memory _project = projectRegistry.getProject(_projectId);

        assertEq(_project.projectName, _projectName);
        assertEq(_project.projectOwner, address(this));
        assertEq(_project.fundingGoal, _fundingGoal);
        assertEq(uint256(_project.projectStatus), uint256(ProjectRegistry.ProjectStatus.Voting));
    }

    function test_submitProject_Returns_Correct_projectId() public {
        uint256 expectedProjectId = 0;
        uint256 _projectId = projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );

        assertEq(expectedProjectId, _projectId);
    }

    function test_approveProject_Reverts_If_Not_Owner() public {
        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );

        uint256 expectedProjectId = 0;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        projectRegistry.approveProject(expectedProjectId);
    }

    function test_approveProject_Reverts_If_Project_ID_Is_Invalid() public {
        uint256 _projectId;
        vm.expectRevert("Project does not exist");
        vm.prank(owner);
        projectRegistry.approveProject(_projectId);
    }

    function test_approveProject_Updates_projectStatus() public {
        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );

        uint256 expectedProjectId = 0;

        ProjectRegistry.Project memory _project = projectRegistry.getProject(expectedProjectId);

        uint8 initialProjectStatus = uint8(_project.projectStatus);

        vm.prank(owner);
        projectRegistry.approveProject(expectedProjectId);

        ProjectRegistry.Project memory _updatedProject = projectRegistry.getProject(expectedProjectId);
        uint8 finalProjectStatus = uint8(_updatedProject.projectStatus);

        assertEq(initialProjectStatus, uint8(ProjectRegistry.ProjectStatus.Voting));
        assertEq(finalProjectStatus, uint8(ProjectRegistry.ProjectStatus.Approved));
    }

    function test_approveProject_Emits() public {
        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );
        uint256 expectedProjectId = 0;

        vm.prank(owner);
        vm.expectEmit();
        emit ProjectApproved(expectedProjectId);
        projectRegistry.approveProject(expectedProjectId);
    }

    function test_rejectProject_Reverts_If_Not_Owner() public {
        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );

        uint256 expectedProjectId = 0;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        projectRegistry.rejectProject(expectedProjectId);
    }

    function test_rejectProject_Reverts_If_Project_ID_Is_Invalid() public {
        uint256 _projectId;
        vm.expectRevert("Project does not exist");
        vm.prank(owner);
        projectRegistry.rejectProject(_projectId);
    }

    function test_rejectProject_Updates_projectStatus() public {
        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );

        uint256 expectedProjectId = 0;

        ProjectRegistry.Project memory _project = projectRegistry.getProject(expectedProjectId);

        uint8 initialProjectStatus = uint8(_project.projectStatus);

        vm.prank(owner);
        projectRegistry.rejectProject(expectedProjectId);

        ProjectRegistry.Project memory _updatedProject = projectRegistry.getProject(expectedProjectId);
        uint8 finalProjectStatus = uint8(_updatedProject.projectStatus);

        assertEq(initialProjectStatus, uint8(ProjectRegistry.ProjectStatus.Voting));
        assertEq(finalProjectStatus, uint8(ProjectRegistry.ProjectStatus.Rejected));
    }

    function test_rejectProject_Emits() public {
        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );
        uint256 expectedProjectId = 0;

        vm.prank(owner);
        vm.expectEmit();
        emit ProjectRejected(expectedProjectId);
        projectRegistry.rejectProject(expectedProjectId);
    }

    function test_getProject() public {
        projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );

        uint256 expectedProjectId = 0;

        ProjectRegistry.Project memory _project = projectRegistry.getProject(expectedProjectId);

        assertEq(_project.projectId, expectedProjectId);
        assertEq(_project.projectName, _projectName);
        assertEq(_project.projectOwner, address(this));
        assertEq(_project.createdAt, block.timestamp);
        assertEq(_project.fundingGoal, _fundingGoal);
    }

    function test_getProject_Reverts_If_Project_ID_Is_Invalid() public {
        uint256 expectedProjectId = 0;

        vm.expectRevert("Project does not exist");
        projectRegistry.getProject(expectedProjectId);
    }
}
