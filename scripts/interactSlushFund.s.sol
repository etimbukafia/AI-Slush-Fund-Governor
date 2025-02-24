// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {SlushFund} from "../contracts/slushFund.sol";
import {MockERC20} from "../contracts/MockERC20.sol";

contract InteractSlushFund is Script {
    SlushFund slushFund;
    MockERC20 mockToken;

    function run() external {
        address member1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address nonMember1 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        address member2 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

        vm.startBroadcast(member2);

        slushFund = SlushFund(
            payable(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512)
        );

        mockToken = MockERC20(
            address(0x5FbDB2315678afecb367f032d93F642f64180aa3)
        );

        uint256 amount = 1000;
        string memory purpose = "To refund customer's losses";

        requestFunds(amount, purpose);

        vm.stopBroadcast();
    }

    function getMembers() internal view {
        // Getting total members
        address[] memory currentMembers = slushFund.viewMembers();

        console.log("Total current members:", currentMembers.length);

        // Logging each memember
        for (uint256 i = 0; i < currentMembers.length; i++) {
            console.log("Member", i + 1, ":", currentMembers[i]);
        }
    }

    function addMembers(address _newMember) internal {
        // Adding new member
        slushFund.addNewMember(_newMember);
        console.log("Latest member: ", _newMember);
    }

    function checkMembership(address _member) internal view {
        bool ismember = slushFund.isMemberCheck(_member);
        if (!ismember) {
            console.log("Not member");
        } else {
            console.log("Is member");
        }
    }

    function getBalance() internal view {
        uint256 balance = slushFund.checkBalance();
        console.log("Vault Balance: ");
        console.logUint(balance);
    }

    function requestFunds(
        uint256 _amount,
        string memory _purpose
    ) internal returns (uint128) {
        uint128 requestCounter = slushFund.requestFunds(_amount, _purpose);
        console.log("request ID: ", requestCounter);

        return requestCounter;
    }
}
