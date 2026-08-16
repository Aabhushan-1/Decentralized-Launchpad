//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ProjectRegistry} from "../src/ProjectRegistry.sol";
import {Governance} from "../src/Governance.sol";
import {FundingRound} from "../src/FundingRound.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract FundingRoundTests is Test {
    FundingRound fundingRound;
    ProjectRegistry projectRegistry;
    Governance governance;

    uint256 private constant _QUORUM = 100;

    uint256 _duration = 30 days;
    string _projectName = "SolarGrid AI";
    string _projectCategory = "Renewable Energy";
    string _projectDescription = "Decentralized micro-grid monitoring using smart contracts.";
    uint256 _fundingGoal = 100000;
    string _projectObjectives = "Deploy 50 solar nodes, complete IoT integration, launch beta.";
    ProjectRegistry.ProjectReturnType _projectReturnType = ProjectRegistry.ProjectReturnType.Payback;

    uint256[] projectIds;

    function setUp() public {
        projectRegistry = new ProjectRegistry(address(this));
        governance = new Governance(address(projectRegistry));
        projectRegistry.transferOwnership(address(governance));

        uint256 _projectId = projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );
        projectIds[0] = _projectId;

        uint256 _sessionId = governance.createSession(_duration, projectIds);
        address tempAddress;
        for (uint256 i = 0; i < _QUORUM; i++) {
            // forge-lint: disable-next-line(unsafe-typecast)
            tempAddress = address(uint160(i + 1));
            vm.prank(tempAddress);
            governance.vote(_sessionId, _projectId);
        }
        vm.warp(block.timestamp + _duration + 1);
        uint256 _winningProjectId = governance.finalizeVoting(_sessionId);

        fundingRound = new FundingRound(_winningProjectId, _duration, address(projectRegistry));
    }
}
