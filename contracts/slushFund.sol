// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVoting} from "./IVoting.sol";

contract SlushFund {
    IVoting public votingContract;
    // ADDRESSES
    address payable private immutable slushVault;

    // ENUMS
    enum RequestError {
        ZeroTotalContributions,
        InsufficientFunds,
        LowContribution,
        InvalidAmount
    }

    enum RequestStatus {
        Pending,
        Accepted,
        Rejected,
        Completed
    }

    // STRUCTS
    struct Request {
        uint128 requestID;
        uint256 amount;
        address member;
        string purpose;
        RequestStatus status;
        //string evidence;
    }

    // MAPPINGS
    mapping(address => uint256) public balances;
    mapping(address => uint256) public amountContributed;
    mapping(address => uint256) public totalReceived;
    mapping(address => bool) public isMember; // Tracks if an address is a contributor
    mapping(uint128 => Request) public withdrawalRequests; // Store requests by ID

    //mapping(address => Withdrawal[]) public withdrawalsByMmeber; // Track withdrawals per member
    //Withdrawal[] public allWithdrawals; //Global tracking of all withdrawals

    uint8 public totalMembers;
    address[] members;

    // EVENTS
    event Contributed(address indexed contributor, uint256 amount);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event WithdrawalRequested(
        uint128 requestID,
        address indexed member,
        uint256 amount,
        string purpose
    );
    event RequestAccepted(
        uint128 requestID,
        address indexed member,
        uint256 amount,
        string purpose,
        string decision
    );
    event RequestRejected(
        uint128 requestID,
        address indexed member,
        uint256 amount,
        string purpose,
        string decision
    );

    event ManualVoting(uint128 requestID);

    // ERRORS
    error NotMember(address nonMember);
    error InvalidAmount(uint256 amount);
    error TransferFailed();
    error NotVaultOwner(address notOwner);
    error MemberAlreadyExists(address member);
    error MemberDoesNotExist(address nonMember);
    error WithdrawalRequestFailed();
    error InsufficientBalance(uint256 amount);

    // VARIABLES
    IERC20 public immutable token;
    uint128 private requestCounter;

    // MODIFIERS
    modifier onlyMember() {
        if (!isMember[msg.sender]) {
            revert NotMember(msg.sender);
        }
        _;
    }

    modifier onlyVaultOwner() {
        if (msg.sender != slushVault) {
            revert NotVaultOwner(msg.sender);
        }
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
        slushVault = payable(msg.sender); // Set the deployer as the vault owner
    }

    function setVotingContract(
        address _votingContract
    ) external onlyVaultOwner {
        votingContract = IVoting(_votingContract);
    }

    function checkBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function contribute(uint256 _amount) public onlyMember {
        if (_amount == 0) {
            revert InvalidAmount(_amount);
        }

        bool success = token.transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert TransferFailed();
        }

        //balances[slushVault] += _amount;
        totalReceived[slushVault] += _amount;
        amountContributed[msg.sender] += _amount;

        emit Contributed(msg.sender, _amount);
    }

    function requestFunds(
        uint256 _amount,
        string memory _purpose
    ) public onlyMember returns (uint128) {
        if (_amount == 0) {
            revert InvalidAmount(_amount);
        }

        if (_amount > token.balanceOf(address(this))) {
            revert InsufficientBalance(_amount);
        }

        requestCounter++;

        Request storage r = withdrawalRequests[requestCounter];
        r.requestID = requestCounter;
        r.amount = _amount;
        r.member = msg.sender;
        r.purpose = _purpose;
        r.status = RequestStatus.Pending;

        emit WithdrawalRequested(requestCounter, msg.sender, _amount, _purpose);

        return requestCounter;
    }

    function handleWithdrawalRequest(
        uint8 _decision,
        uint128 _requestID
    ) public onlyVaultOwner {
        Request storage r = withdrawalRequests[_requestID];
        require(r.requestID == _requestID, "Request does not exist");
        require(
            r.status == RequestStatus.Pending,
            "Request has already been fulfilled"
        );

        if (_decision == 1) {
            r.status = RequestStatus.Rejected;
            emit RequestRejected(
                _requestID,
                r.member,
                r.amount,
                r.purpose,
                "Rejected"
            );
        } else if (_decision == 0) {
            r.status = RequestStatus.Accepted;
            require(token.transfer(r.member, r.amount), "Transfer failed");
            emit RequestAccepted(
                _requestID,
                r.member,
                r.amount,
                r.purpose,
                "Accepted"
            );
        } else {
            emit ManualVoting(_requestID);
        }
    }

    function addNewMember(
        address _newMember
    ) public onlyVaultOwner returns (bool) {
        if (isMember[_newMember]) {
            revert MemberAlreadyExists(_newMember); // Optional: Prevent duplicate entries
        }
        members.push(_newMember);
        isMember[_newMember] = true;
        totalMembers += 1;
        return true;
    }

    function viewMembers() public view returns (address[] memory) {
        return members;
    }

    function isMemberCheck(address member) external view returns (bool) {
        return isMember[member];
    }
}
