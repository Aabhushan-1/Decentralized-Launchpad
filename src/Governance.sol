//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ProjectRegistry} from "../src/ProjectRegistry.sol";

contract Governance {
    struct Proposal {
        uint256 projectId;
        uint256 votes;
    }

    struct VotingSession {
        uint256 sessionId;
        uint256 duration;
        uint256 deadline;
        bool closed;
        Proposal[] proposals;
    }

    ProjectRegistry private projectRegistry;

    constructor(address _projectRegistry) {
        projectRegistry = ProjectRegistry(_projectRegistry);
    }

    modifier sessionOpen(uint256 _sessionId) {
        if (block.timestamp > sessions[_sessionId].deadline) {
            revert("Voting period ended!");
        }

        if (sessions[_sessionId].closed) {
            revert("Session Closed!");
        }

        _;
    }

    modifier sessionExists(uint256 _sessionId) {
        if (_sessionId >= totalSessions) {
            revert("Session does not exist!");
        }
        _;
    }

    uint256 private totalSessions;
    uint256 private constant QUORUM = 100;
    mapping(uint256 => VotingSession) private sessions;
    mapping(address => mapping(uint256 => bool)) private addressHasVoted;

    event SessionCreated(uint256 indexed sessionId);
    event Voted(uint256 indexed sessionId, uint256 indexed projectId, address voter);
    event SessionClosed(uint256 indexed sessionId, uint256 winningProjectId);

    function createSession(uint256 duration, uint256[] memory projectIds) public returns (uint256) {
        uint256 _sessionId = totalSessions;

        VotingSession storage _votingSession = sessions[_sessionId];
        _votingSession.sessionId = _sessionId;
        _votingSession.duration = duration;
        _votingSession.deadline = block.timestamp + duration;
        _votingSession.closed = false;

        for (uint256 i = 0; i < projectIds.length; i++) {
            _votingSession.proposals.push(Proposal({projectId: projectIds[i], votes: 0}));
        }

        totalSessions++;

        emit SessionCreated(_sessionId);
        return _sessionId;
    }

    function vote(uint256 _sessionId, uint256 _projectId) public sessionExists(_sessionId) sessionOpen(_sessionId) {
        address _voter = msg.sender;
        bool found = false;

        VotingSession storage _session = sessions[_sessionId];

        if (addressHasVoted[_voter][_sessionId]) {
            revert("Already voted in this session!");
        }

        for (uint256 i = 0; i < _session.proposals.length; i++) {
            if (_session.proposals[i].projectId == _projectId) {
                _session.proposals[i].votes++;
                addressHasVoted[_voter][_sessionId] = true;

                emit Voted(_sessionId, _projectId, _voter);
                found = true;
                break;
            }
        }

        if (!found) {
            revert("Project Not Found!");
        }
    }

    function finalizeVoting(uint256 _sessionId) public sessionExists(_sessionId) {
        VotingSession storage _session = sessions[_sessionId];
        uint256 proposalLength = _session.proposals.length;

        if (_session.closed) {
            revert("Session Closed!");
        }

        if (_session.deadline > block.timestamp) {
            revert("Deadline not reached!");
        }

        uint256 _totalVotes;
        uint256 _highestVote;
        uint256 _winningProjectId;

        for (uint256 i = 0; i < proposalLength; i++) {
            _totalVotes += _session.proposals[i].votes;
            if (_session.proposals[i].votes > _highestVote) {
                _winningProjectId = _session.proposals[i].projectId;
                _highestVote = _session.proposals[i].votes;
            }
        }

        if (_totalVotes < QUORUM) {
            revert("Not enough total votes!");
        }

        for (uint256 i = 0; i < proposalLength; i++) {
            if (_session.proposals[i].projectId == _winningProjectId) {
                projectRegistry.approveProject(_session.proposals[i].projectId);
            } else {
                projectRegistry.rejectProject(_session.proposals[i].projectId);
            }
        }

        _session.closed = true;

        emit SessionClosed(_sessionId, _winningProjectId);
    }

    function getSession(uint256 _sessionId) public view sessionExists(_sessionId) returns (VotingSession memory) {
        return sessions[_sessionId];
    }
}
