//SPDX-License-Identidier: MIT

pragma solidity ^0.8.19;

import {ProjectRegistry} from "../src/ProjectRegistry.sol";

contract Governance {
    enum SessionStatus {
        ongoing,
        ended
    }

    struct Proposal {
        uint256 projectId;
        uint256 votes;
    }

    struct VotingSession {
        uint256 sessionId;
        uint256 duration;
        uint256 deadline;
        bool executed;
        Proposal[] proposals;
        SessionStatus sessionStatus;
    }

    ProjectRegistry private projectRegistry;

    constructor(address _projectRegistry) {
        projectRegistry = ProjectRegistry(_projectRegistry);
    }

    uint256 private totalSessions;
    uint256 private constant QUORUM = 100;
    mapping(uint256 => VotingSession) private sessions;
    mapping(address => mapping(uint256 => bool)) private addressHasVoted;

    event SessionCreated(uint256 indexed sessionId);
    event Voted(uint256 indexed sessionId, uint256 indexed projectId, address voter);
    event SessionExecuted(uint256 indexed sessionId, uint256 winningProjectId);
}
