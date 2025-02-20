// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SlushFund} from "./slushFund.sol";

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract aiGovernor {
    function handleWithdrawalRequest(
        uint128 requestId,
        address member,
        uint256 amount,
        string memory purpose
    ) external {}
}
