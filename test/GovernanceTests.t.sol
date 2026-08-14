//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Governance} from "../src/Governance.sol";
import {ProjectRegistry} from "../src/ProjectRegistry.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract GovernanceTests is Test {
    Governance governance;
    ProjectRegistry projectRegistry;

    uint256 private constant _QUORUM = 100;
    address voter = address(1);

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

    function _createProjects(uint256 _projectCount) internal returns (uint256[] memory) {
        uint256[] memory _projectIds = new uint256[](_projectCount);
        for (uint256 i = 0; i < _projectCount; i++) {
            _projectIds[i] = projectRegistry.submitProject(
                _projectName,
                _projectCategory,
                _projectDescription,
                _fundingGoal,
                _projectObjectives,
                _projectReturnType
            );
        }

        return _projectIds;
    }

    function _createSession(uint256 duration, uint256 _projectCount) internal returns (uint256, uint256[] memory) {
        uint256[] memory _projectIds = _createProjects(_projectCount);
        return (governance.createSession(duration, _projectIds), _projectIds);
    }

    function _castVote(uint256 _totalVotes, uint256 _sessionId, uint256 _projectId) internal {
        address tempAddress;
        for (uint256 i = 0; i < _totalVotes; i++) {
            // forge-lint: disable-next-line(unsafe-typecast)
            tempAddress = address(uint160(i + 1));
            vm.prank(tempAddress);
            governance.vote(_sessionId, _projectId);
        }
    }

    function test_createSession_Returns_Correct_Session_Id() public {
        uint256 _projectCount = 1;
        uint256 expectedSessionId = 0;

        (uint256 _sessionId,) = _createSession(_duration, _projectCount);

        assertEq(_sessionId, expectedSessionId);
    }

    function test_Session_Is_Created_With_Correct_Data() public {
        uint256 _projectCount = 1;
        (uint256 _sessionId, uint256[] memory _projectIds) = _createSession(_duration, _projectCount);

        uint256 expectedSessionId = 0;

        Governance.Proposal[] memory expectedProposals = new Governance.Proposal[](1);
        expectedProposals[0] = Governance.Proposal({projectId: _projectIds[0], votes: 0});

        Governance.VotingSession memory _votingSession = governance.getSession(_sessionId);

        assertEq(_votingSession.sessionId, expectedSessionId);
        assertEq(_votingSession.deadline, block.timestamp + _duration);
        assertEq(_votingSession.duration, _duration);
        assertEq(_votingSession.closed, false);
        assertEq(abi.encode(_votingSession.proposals), abi.encode(expectedProposals));
    }

    function test_createSession_Emits() public {
        uint256 _projectCount = 1;
        uint256[] memory _projectIds = _createProjects(_projectCount);
        uint256 expectedProjectId = 0;

        vm.expectEmit();
        emit SessionCreated(expectedProjectId);
        governance.createSession(_duration, _projectIds);
    }

    function test_vote_Reverts_If_Session_Doesnt_Exist() public {
        uint256 _projectCount = 1;

        (uint256 _sessionId, uint256[] memory _projectIds) = _createSession(_duration, _projectCount);

        vm.expectRevert("Session does not exist!");
        governance.vote((_sessionId + 1), _projectIds[0]);
    }

    function test_vote_Reverts_If_Session_Is_Closed() public {
        uint256 _projectCount = 1;

        (uint256 _sessionId, uint256[] memory _projectIds) = _createSession(_duration, _projectCount);
        uint256 _projectId = _projectIds[0];
        _castVote(_QUORUM, _sessionId, _projectId);
        vm.warp(_duration + block.timestamp);
        governance.finalizeVoting(_sessionId);

        vm.expectRevert("Session Closed!");
        governance.vote(_sessionId, _projectId);
    }

    function test_vote_Reverts_If_Session_Period_Ended() public {
        uint256 _projectCount = 1;

        (uint256 _sessionId, uint256[] memory _projectIds) = _createSession(_duration, _projectCount);
        uint256 _projectId = _projectIds[0];
        vm.warp(_duration + block.timestamp + 1 days);

        vm.expectRevert("Voting period ended!");
        governance.vote(_sessionId, _projectId);
    }

    function test_vote_Reverts_If_User_Already_Voted() public {
        uint256 _projectCount = 1;

        (uint256 _sessionId, uint256[] memory _projectIds) = _createSession(_duration, _projectCount);
        uint256 _projectId = _projectIds[0];

        vm.prank(voter);
        governance.vote(_sessionId, _projectId);
        vm.expectRevert("Already voted in this session!");
        vm.prank(voter);
        governance.vote(_sessionId, _projectId);
    }

    function test_vote_Reverts_If_Project_Doesnt_Exits() public {
        uint256 _projectCount = 1;

        (uint256 _sessionId, uint256[] memory _projectIds) = _createSession(_duration, _projectCount);
        uint256 _projectId = _projectIds.length;

        vm.expectRevert("Project Not Found!");
        vm.prank(voter);
        governance.vote(_sessionId, _projectId);
    }

    function test_vote_Emits() public {
        uint256 _projectCount = 1;

        (uint256 _sessionId, uint256[] memory _projectIds) = _createSession(_duration, _projectCount);
        uint256 _projectId = _projectIds[0];

        vm.expectEmit();
        emit Voted(_sessionId, _projectId, voter);
        vm.prank(voter);
        governance.vote(_sessionId, _projectId);
    }

    function test_vote_Updates_Mapping() public {
        uint256 _projectCount = 1;

        (uint256 _sessionId, uint256[] memory _projectIds) = _createSession(_duration, _projectCount);
        uint256 _projectId = _projectIds[0];

        bool initialMapping = governance.getAddressHasVoted(voter, _sessionId);

        vm.prank(voter);
        governance.vote(_sessionId, _projectId);

        bool finalMapping = governance.getAddressHasVoted(voter, _sessionId);

        assertEq(initialMapping, false);
        assertEq(finalMapping, true);
    }
}
