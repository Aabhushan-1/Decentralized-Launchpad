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
}
