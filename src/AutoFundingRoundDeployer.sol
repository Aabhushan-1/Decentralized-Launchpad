//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {FundingRound} from "../src/FundingRound.sol";

contract AutoFundingRoundDeployer {
    address private governanceAddress;
    address private _projectRegistry;
    uint256 private _duration;

    mapping(uint256 => address) private projectIdToFundingRound;

    address[] private fundingRoundAddresses;

    event NewFundingRoundDeployed(uint256 indexed winningProjectId, address fundingRound);

    constructor(address _governance, uint256 duration, address projectRegistry) {
        governanceAddress = _governance;
        _projectRegistry = projectRegistry;
        _duration = duration;
    }

    function deployNewFundingRound(uint256 _winningProjectId) public {
        if (msg.sender != governanceAddress) revert("Caller is not governance address");

        if (projectIdToFundingRound[_winningProjectId] != address(0)) revert("Funding round already deployed!");

        FundingRound newFundingRound = new FundingRound(_winningProjectId, _duration, _projectRegistry);
        address addressOfNewFundingRound = address(newFundingRound);

        projectIdToFundingRound[_winningProjectId] = addressOfNewFundingRound;
        fundingRoundAddresses.push(addressOfNewFundingRound);

        emit NewFundingRoundDeployed(_winningProjectId, addressOfNewFundingRound);
    }

    function getFundingRound(uint256 _projectId) public view returns (address) {
        return projectIdToFundingRound[_projectId];
    }

    function getAllFundingRounds() public view returns (address[] memory) {
        return fundingRoundAddresses;
    }
}
