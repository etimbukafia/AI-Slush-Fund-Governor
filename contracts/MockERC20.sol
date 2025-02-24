// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("SlushFundToken", "SFK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount); // _mint() is internal, so we expose it via `mint()`
    }
}
