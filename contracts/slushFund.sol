// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SlushFund {
    // ADDRESSES
    address payable private immutable slushVault;

    // STRUCTS
    struct Request {
        uint256 requestID;
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

    // ARRAYS
    address[] public members; // Need to create dummy addresses

    // ENUMS
    enum RequestError {
        ZeroTotalContributions,
        InsufficientFunds,
        LowContribution
    }
    enum GeneralErrors {
        Unauthorized
    }
    enum RequestStatus {
        Pending,
        Accepted,
        Rejected,
        Completed
    }

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

    // ERRORS
    error NotAuthorizedToDeposit(GeneralErrors reason);
    error InvalidAmount(uint amount);
    error TransferFailed();
    error NotVaultOwner(GeneralErrors reason);
    error MemberAlreadyExists();
    error MemberDoesNotExist();
    error WithdrawalRequestFailed(RequestError reason);

    // VARIABLES
    IERC20 public immutable token;
    uint128 private requestCounter;

    // MODIFIERS
    modifier onlyMember() {
        if (!isMember[msg.sender]) {
            revert NotAuthorizedToDeposit(GeneralErrors.Unauthorized);
        }
        _;
    }

    modifier onlyVaultOwner() {
        if (msg.sender != slushVault) {
            revert NotVaultOwner(GeneralErrors.Unauthorized);
        }
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
        slushVault = payable(msg.sender); // Set the deployer as the vault owner
    }

    function contribute(uint256 _amount) public payable onlyMember {
        if (_amount <= 0) {
            revert InvalidAmount(_amount);
        }

        bool success = token.transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert TransferFailed();
        }

        balances[slushVault] += _amount;
        totalReceived[slushVault] += _amount;
        amountContributed[msg.sender] += _amount;

        emit Contributed(msg.sender, _amount);
    }

    function requestFunds(
        uint256 _amount,
        string calldata _purpose
    ) public payable onlyMember returns (uint128) {
        if (_amount <= 0) {
            revert InvalidAmount(msg.value);
        }

        requestCounter++;
        withdrawalRequests[requestCounter] = Request(
            requestCounter,
            _amount,
            msg.sender,
            _purpose,
            RequestStatus.Pending
        );

        emit WithdrawalRequested(requestCounter, msg.sender, _amount, _purpose);

        return requestCounter;
    }

    function addNewMember(
        address _newMember
    ) public onlyVaultOwner returns (bool) {
        members.push(_newMember);
        return true;
    }

    function viewMembers() public view returns (address[] memory) {
        return members;
    }
}
