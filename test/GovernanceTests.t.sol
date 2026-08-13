//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Governance} from "../src/Governance.sol";
import {ProjectRegistry} from "../src/ProjectRegistry.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract GovernanceTests is Test {
    Governance governance;
    ProjectRegistry projectRegistry;

    uint256 _duration = 30 days;
    string _projectName = "SolarGrid AI";
    string _projectCategory = "Renewable Energy";
    string _projectDescription = "Decentralized micro-grid monitoring using smart contracts.";
    uint256 _fundingGoal = 100000;
    string _projectObjectives = "Deploy 50 solar nodes, complete IoT integration, launch beta.";
    ProjectRegistry.ProjectReturnType _projectReturnType = ProjectRegistry.ProjectReturnType.Payback;

    event SessionCreated(uint256 indexed sessionId);
    event Voted(uint256 indexed sessionId, uint256 indexed projectId, address voter);
    event SessionClosed(uint256 indexed sessionId, uint256 winningProjectId);

    function setUp() public {
        projectRegistry = new ProjectRegistry(address(this));
        governance = new Governance(address(projectRegistry));

        projectRegistry.transferOwnership(address(governance));
    }

    function _submitProject() public returns (uint256) {
        return projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );
    }

    function test_Session_Is_Created_With_Correct_Data() public {
        uint256 _projectId = _submitProject();
        uint256[] memory _projectIds = new uint256[](1);
        _projectIds[0] = _projectId;
        uint256 expectedSessionId = 0;
        uint256 expectedProjectId = 0;

        uint256 _sessionId = governance.createSession(_duration, _projectIds);
        Governance.VotingSession _votingSession = governance.getSession(_sessionId);
        
        assertEq(_votingSession.sessionId, expectedSessionId);
        assertEq(_votingSession.deadline, block.timestamp + _duration);
        assertEq(_votingSession.duration, _duration);
        asserteq(_votingSession.closed, false);
    }
}
