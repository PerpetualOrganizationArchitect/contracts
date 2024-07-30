// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ParticipationVoting.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ParticipationVotingTest is Test {
    ParticipationVoting public participationVoting;
    ParticipationVoting public participationVotingQuadratic;

    IERC20 public participationToken;
    INFTMembership5 public nftMembership;
    ITreasury3 public treasury;

    address public owner = address(1);
    address public voter1 = address(2);
    address public voter2 = address(3);
    address public voter3 = address(4);
    address public treasuryAddress = address(5);

    uint256 public quorumPercentage = 51;

    string[] public allowedRoleNames = ["member"];
    string[] public optionNames = ["Option1", "Option2"];
    bool public quadraticVotingEnabled = false;

    function setUp() public {
        participationToken = IERC20(address(new ERC20Mock("Participation Token", "PT")));
        nftMembership = new NFTMembershipMock();
        treasury = new TreasuryMock();

        participationVoting = new ParticipationVoting(
            address(participationToken),
            address(nftMembership),
            allowedRoleNames,
            quadraticVotingEnabled,
            address(treasury),
            quorumPercentage
        );

        participationVotingQuadratic = new ParticipationVoting(
            address(participationToken),
            address(nftMembership),
            allowedRoleNames,
            true,
            address(treasury),
            quorumPercentage
        );

        // Set initial balances
        deal(address(participationToken), voter1, 100);
        deal(address(participationToken), voter2, 100);
        deal(address(participationToken), voter3, 100);

        // set owner as member
        NFTMembershipMock(address(nftMembership)).setMemberType(owner, "member");

        deal(address(participationToken), address(treasury), 1000 * 10 ** 18);
    }

    function testCreateProposal() public {
        vm.prank(owner);
        participationVoting.createProposal(
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
        ) = participationVoting.getProposal(0);

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
        participationVoting.createProposal(
            "Proposal1", "Description1", 60, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );

        vm.prank(voter1);
        participationVoting.vote(0, voter1, 0);

        (uint256 votes) = participationVoting.getOptionVotes(0, 0);
        assertEq(votes, 100);

        (uint256 totalVotes,,,,,,,) = participationVoting.getProposal(0);
        assertEq(totalVotes, 100);
    }

    function testAnnounceWinner() public {
        vm.prank(owner);
        participationVoting.createProposal(
            "Proposal1",
            "Description1",
            1, // 1 minute for quick expiration
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            true,
            address(participationToken)
        );

        vm.prank(voter1);
        participationVoting.vote(0, voter1, 0);

        vm.warp(block.timestamp + 2 minutes);

        vm.prank(owner);
        participationVoting.announceWinner(0);

        (uint256 winningOptionIndex, bool hasValidWinner) = participationVoting.getWinner(0);
        assertEq(winningOptionIndex, 0);
        assertEq(hasValidWinner, true);
    }

    function testQuadraticVoting() public {
        vm.prank(owner);
        participationVotingQuadratic.createProposal(
            "Proposal1", "Description1", 60, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );

        vm.prank(voter1);
        participationVotingQuadratic.vote(0, voter1, 0);

        (uint256 votes) = participationVotingQuadratic.getOptionVotes(0, 0);

        // square root of 100 is 10
        uint256 expectedQuadraticVotes = 10;
        assertEq(votes, expectedQuadraticVotes);

        (uint256 totalVotes,,,,,,,) = participationVotingQuadratic.getProposal(0);
        assertEq(totalVotes, expectedQuadraticVotes);
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

contract NFTMembershipMock is INFTMembership5 {
    mapping(address => string) public memberType;

    function checkMemberTypeByAddress(address user) external view returns (string memory) {
        return memberType[user];
    }

    function setMemberType(address user, string memory _type) external {
        memberType[user] = _type;
    }
}

contract TreasuryMock is ITreasury3 {
    function sendTokens(address _token, address _to, uint256 _amount) external {
        ERC20Mock(_token).transfer(_to, _amount);
    }

    function withdrawEther(address payable _to, uint256 _amount) external {
        _to.transfer(_amount);
    }
}
