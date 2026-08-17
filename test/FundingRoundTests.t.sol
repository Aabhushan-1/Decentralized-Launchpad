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

    address user = makeAddr("user");
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

    event Funded(address funder, uint256 _winningProjectId, uint256 _amount);
    event Withdrawn(address owner, uint256 _winningProjectId, uint256 _amount);
    event Refunded(address contributor, uint256 _winningProjectId, uint256 _amount);
    event RoundFinalized(uint256 _winningProjectId, FundingRound.FundingStatus fundingStatus);

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

        fundingRound = new FundingRound(_winningProjectId, _duration, address(projectRegistry));
    }

    function test_projectId_Is_Rejected_Constructor_Will_Revert() public {
        uint256 _projectId_2 = projectRegistry.submitProject(
            _projectName, _projectCategory, _projectDescription, _fundingGoal, _projectObjectives, _projectReturnType
        );
        projectIds.push(_projectId_2);

        vm.expectRevert("Project Not Approved");
        new FundingRound(_projectId_2, _duration, address(projectRegistry));
    }

    function test_fund_Reverts_If_FundingStatus_Is_Not_Active() public {
        fundingRound.fund{value: _fundingGoal}();

        vm.expectRevert("FundingRound Not Active!");
        fundingRound.fund{value: 1 ether}();
    }

    function test_fund_Reverts_If_Deadline_Reached() public {
        vm.warp(block.timestamp + _duration);
        vm.expectRevert("Deadline Reached!");
        fundingRound.fund{value: 1 ether}();

        vm.warp(block.timestamp + _duration + 1);
        vm.expectRevert("Deadline Reached!");
        fundingRound.fund{value: 1 ether}();
    }

    function test_fund_Reverts_If_Amount_Exceeds_Funding_Goal() public {
        vm.expectRevert("Exceeds Funding Goal!");
        fundingRound.fund{value: _fundingGoal + 1 ether}();
    }

    function test_fund_Reverts_If_Amount_Exceeds_Remaining_Required_Amount_To_Reach_Funding_Goal() public {
        uint256 _amount = _fundingGoal - 1;
        fundingRound.fund{value: _amount}();

        vm.expectRevert("Exceeds Funding Goal!");
        fundingRound.fund{value: 2 ether}();
    }

    function test_fund_Emits() public {
        vm.expectEmit();
        emit Funded(address(this), _winningProjectId, _fundingGoal);
        fundingRound.fund{value: _fundingGoal}();
    }

    function test_fund_Updates_amountContributed_Mapping() public {
        vm.prank(user);
        vm.deal(user, _fundingGoal);
        fundingRound.fund{value: _fundingGoal}();

        assertEq(fundingRound.getAmountContributed(user), _fundingGoal);
    }

    function test_fund_Updates_totalFundRaised() public {
        uint256 initialTotalFundRaised = fundingRound.getTotalFundRaised();

        vm.prank(user);
        vm.deal(user, _fundingGoal);
        fundingRound.fund{value: _fundingGoal}();

        uint256 finalTotalFundRaised = fundingRound.getTotalFundRaised();

        assertEq(finalTotalFundRaised, initialTotalFundRaised + _fundingGoal);
    }

    function test_fund_Updates_FundingStatus_If_Goal_Reached() public {
        FundingRound.FundingStatus initialStatus = fundingRound.getFundingStatus();

        fundingRound.fund{value: _fundingGoal}();

        FundingRound.FundingStatus finalStatus = fundingRound.getFundingStatus();

        assertEq(abi.encode(initialStatus), abi.encode(FundingRound.FundingStatus.Active));
        assertEq(abi.encode(finalStatus), abi.encode(FundingRound.FundingStatus.Successful));
    }

    function test_withdraw_Reverts_If_Funding_Not_Successful() public {
        vm.expectRevert("Funding Not Successful!");
        fundingRound.withdraw();
    }

    function test_withdraw_Reverts_If_Not_Owner() public {
        fundingRound.fund{value: _fundingGoal}();

        vm.prank(user);
        vm.expectRevert("Not Project Owner!");
        fundingRound.withdraw();
    }

    function test_withdraw_Increases_projectOwners_Balance() public {
        fundingRound.fund{value: _fundingGoal}();

        uint256 initialBalanceOfOwner = projectOwner.balance;
        vm.prank(projectOwner);
        fundingRound.withdraw();
        uint256 finalBalanceOfOwner = projectOwner.balance;

        assertEq(finalBalanceOfOwner, initialBalanceOfOwner + _fundingGoal);
    }

    function test_withdraw_Emits() public {
        fundingRound.fund{value: _fundingGoal}();

        vm.prank(projectOwner);
        vm.expectEmit();
        emit Withdrawn(projectOwner, _winningProjectId, _fundingGoal);
        fundingRound.withdraw();
    }

    function test_withdraw_Resets_totalFundRaised() public {
        fundingRound.fund{value: _fundingGoal}();

        uint256 initialTotalFundRaised = fundingRound.getTotalFundRaised();

        vm.prank(projectOwner);
        fundingRound.withdraw();

        uint256 finalTotalFundRaised = fundingRound.getTotalFundRaised();

        assertEq(finalTotalFundRaised, initialTotalFundRaised - _fundingGoal);
        assertEq(finalTotalFundRaised, 0);
    }

    function test_withdraw_Updates_FundingStatus() public {
        fundingRound.fund{value: _fundingGoal}();

        FundingRound.FundingStatus initialStatus = fundingRound.getFundingStatus();
        vm.prank(projectOwner);
        fundingRound.withdraw();
        FundingRound.FundingStatus finalStatus = fundingRound.getFundingStatus();

        assertEq(abi.encode(initialStatus), abi.encode(FundingRound.FundingStatus.Successful));
        assertEq(abi.encode(finalStatus), abi.encode(FundingRound.FundingStatus.Withdrawn));
    }

    function test_refund_Reverts_If_FundingState_Not_Failed() public {
        vm.expectRevert("Funding Not Failed!");
        fundingRound.refund();
    }

    function test_refund_Reverts_If_Caller_Has_No_Contribution() public {
        vm.warp(block.timestamp + _duration);
        fundingRound.finalizeRound();

        vm.expectRevert("No Contribution For Refund!");
        fundingRound.refund();
    }

    function test_refund_Emits() public {
        uint256 _amount = 0.01 ether;
        vm.prank(user);
        vm.deal(user, 1 ether);
        fundingRound.fund{value: _amount}();

        vm.warp(block.timestamp + _duration);
        fundingRound.finalizeRound();

        vm.prank(user);
        vm.expectEmit();
        emit Refunded(user, _winningProjectId, _amount);
        fundingRound.refund();
    }

    function test_refund_Resets_amountContributed() public {
        uint256 _amount = 0.01 ether;
        vm.prank(user);
        vm.deal(user, 1 ether);
        fundingRound.fund{value: _amount}();

        uint256 initialAmountContributed = fundingRound.getAmountContributed(user);

        vm.warp(block.timestamp + _duration);
        fundingRound.finalizeRound();

        vm.prank(user);
        fundingRound.refund();

        uint256 finalAmountContributed = fundingRound.getAmountContributed(user);

        assertEq(initialAmountContributed, _amount);
        assertEq(finalAmountContributed, 0);
    }

    function test_finalizeRound_Reverts_If_Deadline_Not_Reached() public {
        vm.expectRevert("Deadline not reached!");
        fundingRound.finalizeRound();
    }

    function test_finalizeRound_Reverts_If_Already_Finalized() public {
        vm.warp(block.timestamp + _duration);
        fundingRound.finalizeRound();

        vm.expectRevert("Already Finalized!");
        fundingRound.finalizeRound();
    }

    function test_finalizeRound_Updates_FundingStatus() public {
        vm.warp(block.timestamp + _duration);
        fundingRound.finalizeRound();

        assertEq(abi.encode(fundingRound.getFundingStatus()), abi.encode(FundingRound.FundingStatus.Failed));
    }

    function test_finalizeRound_Emits() public {
        vm.warp(block.timestamp + _duration);
        vm.expectEmit();
        emit RoundFinalized(_winningProjectId, FundingRound.FundingStatus.Failed);
        fundingRound.finalizeRound();
    }
}
