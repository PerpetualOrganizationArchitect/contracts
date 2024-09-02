// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ParticipationToken is ERC20, Ownable {
    address private taskManagerAddress;
    INFTMembership9 public nftMembership;

    struct TokenRequest {
        address requester;
        uint256 amount;
        string ipfsHash;
        bool approved;
        bool exists;
    }

    mapping(uint256 => TokenRequest) public tokenRequests;
    uint256 public requestCounter;

    event Mint(address indexed to, uint256 amount);
    event TaskManagerAddressSet(address taskManagerAddress);
    event TokenRequested(uint256 requestId, address indexed requester, uint256 amount, string ipfsHash);
    event TokenRequestApproved(uint256 requestId, address indexed approver);

    constructor(string memory name, string memory symbol, address nftMembershipAddress) ERC20(name, symbol) {
        taskManagerAddress = address(0);
        nftMembership = INFTMembership9(nftMembershipAddress);
        requestCounter = 0;
    }

    modifier onlyTaskManager() {
        require(msg.sender == taskManagerAddress, "Only the task manager can call this function.");
        _;
    }

    modifier onlyExecutive() {
        require(
            keccak256(abi.encodePacked(nftMembership.checkMemberTypeByAddress(msg.sender)))
                == keccak256(abi.encodePacked("Executive")),
            "Caller is not an executive."
        );
        _;
    }

    modifier notRequester(uint256 requestId) {
        require(msg.sender != tokenRequests[requestId].requester, "Requester cannot approve their own request.");
        _;
    }

    modifier isMember() {
        require(
            keccak256(abi.encodePacked(nftMembership.checkMemberTypeByAddress(msg.sender)))
                != keccak256(abi.encodePacked("")),
            "Caller is not a member."
        );
        _;
    }

    function mint(address to, uint256 amount) public onlyTaskManager {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    function setTaskManagerAddress(address _taskManagerAddress) external {
        require(taskManagerAddress == address(0), "Task manager address already set.");
        taskManagerAddress = _taskManagerAddress;
        emit TaskManagerAddressSet(_taskManagerAddress);
    }

    function requestTokens(uint256 amount, string memory ipfsHash) public isMember {
        requestCounter++;
        tokenRequests[requestCounter] =
            TokenRequest({requester: msg.sender, amount: amount, ipfsHash: ipfsHash, approved: false, exists: true});
        emit TokenRequested(requestCounter, msg.sender, amount, ipfsHash);
    }

    function approveRequest(uint256 requestId) public onlyExecutive notRequester(requestId) {
        require(tokenRequests[requestId].exists, "Request does not exist.");
        require(!tokenRequests[requestId].approved, "Request already approved.");

        tokenRequests[requestId].approved = true;
        _mint(tokenRequests[requestId].requester, tokenRequests[requestId].amount);
        emit TokenRequestApproved(requestId, msg.sender);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        revert("Transfers are disabled.");
    }

    function getTaskManagerAddress() external view returns (address) {
        return taskManagerAddress;
    }
}

interface INFTMembership9 {
    function checkMemberTypeByAddress(address user) external view returns (string memory);
}
