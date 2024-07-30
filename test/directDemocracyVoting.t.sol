// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DirectDemocracyVoting.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DirectDemocracyVotingTest is Test {
    DirectDemocracyVoting public directDemocracyVoting;

    IERC20 public democracyToken;
    INFTMembership2 public nftMembership;
    ITreasury public treasury;

    address public owner = address(1);
    address public voter1 = address(2);
    address public voter2 = address(3);
    address public voter3 = address(4);
    address public treasuryAddress = address(5);

    uint256 public quorumPercentage = 51;

    string[] public allowedRoleNames = ["member"];
    string[] public optionNames = ["Option1", "Option2"];

    function setUp() public {
        democracyToken = IERC20(address(new ERC20Mock("Democracy Token", "DDT")));
        nftMembership = new NFTMembershipMock();
        treasury = new TreasuryMock();

        directDemocracyVoting = new DirectDemocracyVoting(
            address(democracyToken), address(nftMembership), allowedRoleNames, address(treasury), quorumPercentage
        );

        // Set initial balances
        deal(address(democracyToken), voter1, 100);
        deal(address(democracyToken), voter2, 100);
        deal(address(democracyToken), voter3, 100);

        // set owner as member
        NFTMembershipMock(address(nftMembership)).setMemberType(owner, "member");

        deal(address(democracyToken), address(treasury), 1000 * 10 ** 18);
    }

    function testCreateProposal() public {
        vm.prank(owner);
        directDemocracyVoting.createProposal(
            "Proposal1", "Description1", 60, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );

        (
            uint256 totalVotes,
            uint256 timeInMinutes,
            uint256 creationTimestamp,
            uint256 transferTriggerOptionIndex,
            address payable transferRecipient,
            uint256 transferAmount,
            bool transferEnabled,
            address transferToken
        ) = directDemocracyVoting.getProposal(0);

        assertEq(timeInMinutes, 60);
        assertEq(totalVotes, 0);
        assertEq(creationTimestamp > 0, true);
        assertEq(transferTriggerOptionIndex, 0);
        assertEq(transferRecipient, treasuryAddress);
        assertEq(transferAmount, 100);
        assertEq(transferEnabled, false);
        assertEq(transferToken, address(0));
    }

    function testVote() public {
        vm.prank(owner);
        directDemocracyVoting.createProposal(
            "Proposal1", "Description1", 60, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );

        vm.prank(voter1);
        directDemocracyVoting.vote(0, voter1, 0);

        uint256 votes = directDemocracyVoting.getOptionVotes(0, 0);
        assertEq(votes, 1);

        (uint256 totalVotes,,,,,,,) = directDemocracyVoting.getProposal(0);
        assertEq(totalVotes, 1);
    }

    function testAnnounceWinner() public {
        vm.prank(owner);
        directDemocracyVoting.createProposal(
            "Proposal1",
            "Description1",
            1, // 1 minute for quick expiration
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            true,
            address(democracyToken)
        );

        vm.prank(voter1);
        directDemocracyVoting.vote(0, voter1, 0);

        vm.warp(block.timestamp + 2 minutes);

        vm.prank(owner);
        directDemocracyVoting.announceWinner(0);

        (uint256 winningOptionIndex, bool hasValidWinner) = directDemocracyVoting.getWinner(0);
        assertEq(winningOptionIndex, 0);
        assertEq(hasValidWinner, true);
    }

    function testNonMemberCannotCreateProposal() public {
        address nonMember = address(6); // Address that is not set as a member
        vm.prank(nonMember); // Use non-member account to call the function

        vm.expectRevert("Not authorized to create proposal"); // Expect revert with the specified error message

        directDemocracyVoting.createProposal(
            "Proposal1", "Description1", 60, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );
    }
}

// Mock Contracts
contract ERC20Mock is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address _to, uint256 _amount) external returns (bool) {
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        return true;
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        allowance[msg.sender][_spender] = _amount;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        return true;
    }

    function mint(address _to, uint256 _amount) external {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function burn(address _from, uint256 _amount) external {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }
}

contract NFTMembershipMock is INFTMembership2 {
    mapping(address => string) public memberType;

    function checkMemberTypeByAddress(address user) external view returns (string memory) {
        return memberType[user];
    }

    function setMemberType(address user, string memory _type) external {
        memberType[user] = _type;
    }
}

contract TreasuryMock is ITreasury {
    function sendTokens(address _token, address _to, uint256 _amount) external {
        ERC20Mock(_token).transfer(_to, _amount);
    }

    function setVotingContract(address _votingContract) external {}

    function withdrawEther(address payable _to, uint256 _amount) external {
        _to.transfer(_amount);
    }
}
