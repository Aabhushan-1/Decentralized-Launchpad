//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ProjectRegistry} from "../src/ProjectRegistry.sol";

contract FundingRound {
    uint256 private deadline;
    uint256 private immutable winningProjectId;
    address private immutable projectOwner;
    ProjectRegistry private immutable projectRegistry;
    uint256 private immutable fundingGoal;
    FundingStatus private fundingStatus;
    uint256 private totalFundRaised;

    mapping(address => uint256) private amountContributed;

    enum FundingStatus {
        Active,
        Successful,
        Withdrawn,
        Failed
    }

    event Funded(address funder, uint256 _winningProjectId, uint256 _amount);
    event Withdrawn(address owner, uint256 _winningProjectId, uint256 _amount);
    event Refunded(address contributor, uint256 _winningProjectId, uint256 _amount);
    event RoundFinalized(uint256 _winningProjectId, FundingStatus status);

    constructor(uint256 _winningProjectId, uint256 _duration, address _projectRegistry) {
        projectRegistry = ProjectRegistry(_projectRegistry);

        if (projectRegistry.getProject(_winningProjectId).projectStatus != ProjectRegistry.ProjectStatus.Approved) {
            revert("Project Not Approved");
        }

        winningProjectId = _winningProjectId;
        projectOwner = projectRegistry.getProject(winningProjectId).projectOwner;
        fundingGoal = projectRegistry.getProject(winningProjectId).fundingGoal;
        deadline = block.timestamp + _duration;
        fundingStatus = FundingStatus.Active;
    }

    function fund() public payable {
        if (fundingStatus != FundingStatus.Active) {
            revert("FundingRound Not Active!");
        }

        if (block.timestamp >= deadline) {
            revert("Deadline Reached!");
        }

        address _funder = msg.sender;
        uint256 _amount = msg.value;

        if (totalFundRaised + _amount > fundingGoal) {
            revert("Exceeds Funding Goal!");
        }

        amountContributed[_funder] += _amount;
        totalFundRaised += _amount;

        if (totalFundRaised == fundingGoal) {
            fundingStatus = FundingStatus.Successful;
        }

        emit Funded(_funder, winningProjectId, _amount);
    }

    function withdraw() public {
        if (fundingStatus != FundingStatus.Successful) {
            revert("Funding Not Successful!");
        }

        if (msg.sender != projectOwner) {
            revert("Not Project Owner!");
        }

        uint256 _amount = totalFundRaised;
        totalFundRaised = 0;
        fundingStatus = FundingStatus.Withdrawn;

        (bool success,) = projectOwner.call{value: _amount}("");
        require(success, "Transaction Failed!");

        emit Withdrawn(projectOwner, winningProjectId, _amount);
    }

    function refund() public {
        if (fundingStatus != FundingStatus.Failed) {
            revert("Funding Not Failed!");
        }

        if (amountContributed[msg.sender] == 0) {
            revert("No Contribution For Refund!");
        }

        uint256 _amount = amountContributed[msg.sender];
        amountContributed[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "Transaction Failed!");

        emit Refunded(msg.sender, winningProjectId, _amount);
    }

    function finalizeRound() public {
        if (block.timestamp < deadline) {
            revert("Deadline not reached!");
        }

        if (fundingStatus != FundingStatus.Active) {
            revert("Already Finalized!");
        }

        fundingStatus = FundingStatus.Failed;

        emit RoundFinalized(winningProjectId, fundingStatus);
    }

    function getAmountContributed(address _funder) public view returns (uint256 _amount) {
        return amountContributed[_funder];
    }

    function getTotalFundRaised() public view returns (uint256 _totalFundRaised) {
        return totalFundRaised;
    }

    function getFundingStatus() public view returns (FundingStatus _fundingStatus) {
        return fundingStatus;
    }
}
