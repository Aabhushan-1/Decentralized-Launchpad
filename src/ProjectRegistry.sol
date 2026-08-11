//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract ProjectRegistry {
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
}
