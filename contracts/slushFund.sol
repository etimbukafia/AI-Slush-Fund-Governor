// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract SlushFund {
    // ADDRESSES
    address payable private immutable slushVault;

    // MAPPINGS
    mapping(address => uint256) public balances;
    mapping(address => uint256) public amountContributed;
    mapping(address => uint256) public totalReceived;
    mapping(address => bool) public isMember; // Tracks if an address is a contributor

    // ARRAYS
    address[] public contributors; // Need to create dummy addresses

    // EVENTS
    event Contributed(address indexed contributor, uint256 amount);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);

    // ERRORS
    error NotAuthorizedToDeposit(address contributor);
    error InvalidAmount(uint amount);
    error TransferFailed();
    error NotVaultOwner();
    error MemberAlreadyExists();
    error MemberDoesNotExist();

    // VARIABLES
    IERC20 public immutable token;

    // MODIFIERS
    modifier onlyMember() {
        if (!isMember[msg.sender]) {
            revert NotAuthorizedToDeposit(msg.sender);
        }
        _;
    }

    modifier onlyVaultOwner() {
        if (msg.sender != slushVault) {
            revert NotVaultOwner();
        }
        _;
    }
    
    constructor(address _token) {
        token = IERC20(_token);
        slushVault = payable(msg.sender); // Set the deployer as the vault owner
    }

    function contribute(uint256 _amount) public payable onlyMember returns (uint256) {
        if (msg.value <= 0) {
            revert InvalidAmount(msg.value);
        }

        token.transferFrom(msg.sender, address(this), _amount)
        balances[slushVault] += _amount;
        amountContributed[msg.sender] += _amount;

        emit Contributed(msg.sender, _amount)
        return balances[msg.sender]
    }

    function requestFunds(uint256 amount, string reason) public payable onlyMember returns (bool) {
        if (msg.value <= 0) {
            revert InvalidAmount(msg.value);
        }


    }

}