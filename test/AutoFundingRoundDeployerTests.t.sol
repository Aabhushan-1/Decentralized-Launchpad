//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AutoFundingRoundDeployer} from "../src/AutoFundingRoundDeployer.sol";
import {Governance} from "../src/Governance.sol";
import {ProjectRegistry} from "../src/ProjectRegistry.sol";
import {FundingRound} from "../src/FundingRound.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract AutoFundingRoundDeployerTests is Test {
    AutoFundingRoundDeployer autoFundingRoundDeployer;
    Governance governance;
    ProjectRegistry projectRegistry;

    address projectOwner = makeAddr("projectOwner");

    uint256 private constant _QUORUM = 100;
    uint256 _duration = 30 days;
    string _projectName = "SolarGrid AI";
    string _projectCategory = "Renewable Energy";
    string _projectDescription = "Decentralized micro-grid monitoring using smart contracts.";
    uint256 _fundingGoal = 100000 ether;
    string _projectObjectives = "Deploy 50 solar nodes, complete IoT integration, launch beta.";
    ProjectRegistry.ProjectReturnType _projectReturnType = ProjectRegistry.ProjectReturnType.Payback;

    uint256[] projectIds;
    uint256 _winningProjectId;

    event NewFundingRoundDeployed(uint256 indexed winningProjectId, address fundingRound);

    function setUp() public {
        projectRegistry = new ProjectRegistry(address(this));
        governance = new Governance(address(projectRegistry));
        projectRegistry.transferOwnership(address(governance));

        vm.prank(projectOwner);
        uint256 _projectId = projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );
        projectIds.push(_projectId);

        uint256 _sessionId = governance.createSession(_duration, projectIds);
        address tempAddress;
        for (uint256 i = 0; i < _QUORUM; i++) {
            // forge-lint: disable-next-line(unsafe-typecast)
            tempAddress = address(uint160(i + 1));
            vm.prank(tempAddress);
            governance.vote(_sessionId, _projectId);
        }
        vm.warp(block.timestamp + _duration + 1);
        _winningProjectId = governance.finalizeVoting(_sessionId);

        autoFundingRoundDeployer =
            new AutoFundingRoundDeployer(address(governance), _duration, address(projectRegistry));
    }

    function test_deployNewFundingRound_Reverts_If_Caller_Is_Not_Governance() public {
        vm.expectRevert("Caller is not governance address");
        autoFundingRoundDeployer.deployNewFundingRound(_winningProjectId);
    }

    function test_deployNewFundingRound_Reverts_If_Funding_Round_Already_Deployed() public {
        vm.prank(address(governance));
        autoFundingRoundDeployer.deployNewFundingRound(_winningProjectId);

        vm.prank(address(governance));
        vm.expectRevert("Funding round already deployed!");
        autoFundingRoundDeployer.deployNewFundingRound(_winningProjectId);
    }

    function test_deployNewFundingRound_Updates_projectIdToFundingRound_Mapping() public {
        address initialMapping = autoFundingRoundDeployer.getFundingRound(_winningProjectId);

        vm.prank(address(governance));
        autoFundingRoundDeployer.deployNewFundingRound(_winningProjectId);

        address finalMapping = autoFundingRoundDeployer.getFundingRound(_winningProjectId);

        assertEq(initialMapping, address(0));
        assert(finalMapping != address(0));
    }

    function test_deployNewFundingRound_Updates_fundingRoundAddresses_Array() public {
        uint256 initialArrayLenght = autoFundingRoundDeployer.getAllFundingRounds().length;

        vm.prank(address(governance));
        autoFundingRoundDeployer.deployNewFundingRound(_winningProjectId);

        uint256 finalArrayLenght = autoFundingRoundDeployer.getAllFundingRounds().length;

        assertEq(finalArrayLenght, initialArrayLenght + 1);
    }

    function test_deployNewFundingRound_Emits() public {
        uint256 nonce = vm.getNonce(address(autoFundingRoundDeployer));
        address expectedAddressOfNewFundingRound = vm.computeCreateAddress(address(autoFundingRoundDeployer), nonce);
        vm.prank(address(governance));
        vm.expectEmit();
        emit NewFundingRoundDeployed(_winningProjectId, expectedAddressOfNewFundingRound);
        autoFundingRoundDeployer.deployNewFundingRound(_winningProjectId);
    }
}
