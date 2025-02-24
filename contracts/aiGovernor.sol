// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SlushFund} from "./slushFund.sol";

contract Voting {
    SlushFund public slushfund;

    uint256 public constant VOTING_PERIOD = 172800;

    struct Vote {
        uint128 requestID; // tracks requestID
        mapping(address => bool) hasVoted; // tracks if a member has voted
        mapping(uint8 => uint8) voteCount; // tracks the number of vote for each decision
        uint128 totalVotes;
        uint256 startTime;
        bool isActive;
    }

    mapping(uint128 => Vote) votes;

    error OnlyVaultOwner(address notVaultOwner);
    error OnlyMember(address notMember);
    error VotingAlreadyActive(uint128 requestID);
    error VotingNotActive(uint128 requestID);
    error VotingEnded(uint128 requestID);
    error VotingStillInProgress(uint128 requestID);
    error AlreadyVoted(address member);

    constructor(address _slushFund) {
        slushfund = SlushFund(_slushFund);
    }

    function startVoting(uint128 requestID) external {
        if (msg.sender != address(slushfund)) revert OnlyVaultOwner(msg.sender);
        Vote storage v = votes[requestID];
        if (v.isActive) revert VotingAlreadyActive(requestID);

        v.requestID = requestID;
        v.startTime = block.timestamp;
        v.isActive = true;
    }

    function vote(uint8 decision, uint128 requestID) external {
        if (!slushfund.isMember(msg.sender)) revert OnlyMember(msg.sender);
        Vote storage v = votes[requestID];
        if (!v.isActive) revert VotingNotActive(requestID);
        if (block.timestamp >= v.startTime + VOTING_PERIOD)
            revert VotingEnded(requestID);
        if (v.hasVoted[msg.sender] == true) revert AlreadyVoted(msg.sender);

        v.voteCount[decision] += 1;
        v.totalVotes += 1;
        v.hasVoted[msg.sender] = true;
    }

    function finalizeVoting(uint128 requestID) external returns (uint8) {
        Vote storage v = votes[requestID];
        if (!v.isActive) revert VotingNotActive(requestID);
        if (
            block.timestamp < (v.startTime + VOTING_PERIOD) ||
            v.totalVotes == slushfund.totalMembers()
        ) revert VotingStillInProgress(requestID);
        v.isActive = false;
        uint8 decision = countVotes(requestID);
        slushfund.handleWithdrawalRequest(decision, requestID);
        return decision;
    }

    function countVotes(uint128 requestID) public view returns (uint8) {
        Vote storage v = votes[requestID];
        uint8 accepted = v.voteCount[0];
        uint rejected = v.voteCount[1];
        return accepted > rejected ? 0 : 1;
    }
}
