//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ProjectRegistry is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    enum ProjectReturnType {
        Payback,
        Interest,
        Nothing
    }

    enum ProjectStatus {
        Voting,
        Approved,
        Rejected,
        FundRaising,
        OnGoing,
        Completed
    }

    struct Project {
        uint256 projectId;
        address projectOwner;
        string projectName;
        string projectCategory;
        string projectDescription;
        uint256 createdAt;
        uint256 fundingGoal;
        string projectObjectives;
        ProjectReturnType projectReturnType;
        ProjectStatus projectStatus;
    }

    uint256 private totalProjects;
    mapping(uint256 => Project) private projectIdToProject;

    event ProjectSubmitted(uint256 indexed projectId);
    event ProjectApproved(uint256 indexed projectId);
    event ProjectRejected(uint256 indexed projectId);

    function submitProject(
        string memory _projectName,
        string memory _projectCategory,
        string memory _projectDescription,
        uint256 _fundingGoal,
        string memory _projectObjectives,
        ProjectReturnType _projectReturnType
    ) public {
        uint256 _projectId = totalProjects;
        address _projectOwner = msg.sender;
        uint256 _createdAt = block.timestamp;
        ProjectStatus _projectStatus = ProjectStatus.Voting;

        projectIdToProject[_projectId] = Project(
            _projectId,
            _projectOwner,
            _projectName,
            _projectCategory,
            _projectDescription,
            _createdAt,
            _fundingGoal,
            _projectObjectives,
            _projectReturnType,
            _projectStatus
        );
        totalProjects++;

        emit ProjectSubmitted(_projectId);
    }

    function approveProject(uint256 _projectId) public onlyOwner {
        Project storage _project = projectIdToProject[_projectId];
        _project.projectStatus = ProjectStatus.Approved;

        emit ProjectApproved(_projectId);
    }

    function rejectProject(uint256 _projectId) public onlyOwner {
        Project storage _project = projectIdToProject[_projectId];
        _project.projectStatus = ProjectStatus.Rejected;

        emit ProjectRejected(_projectId);
    }

    function getProject(uint256 _projectId) public view returns (Project memory) {
        return projectIdToProject[_projectId];
    }
}
