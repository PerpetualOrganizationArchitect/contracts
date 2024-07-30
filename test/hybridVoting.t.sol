// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/HybridVoting.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HybridVotingTest is Test {
    HybridVoting public hybridVoting;
    HybridVoting public hybridVotingQuadratic;

    IERC20 public participationToken;
    IERC20 public democracyToken;
    INFTMembership3 public nftMembership;
    ITreasury2 public treasury;

    address public owner = address(1);
    address public voter1 = address(2);
    address public voter2 = address(3);
    address public voter3 = address(4);
    address public treasuryAddress = address(5);

    uint256 public democracyVoteWeight = 73;
    uint256 public participationVoteWeight = 27;
    uint256 public quorumPercentage = 51;

    string[] public allowedRoleNames = ["member"];
    string[] public optionNames = ["Option1", "Option2"];
    bool public quadraticVotingEnabled = false;

    function setUp() public {
        participationToken = IERC20(address(new ERC20Mock("Participation Token", "PT")));
        democracyToken = IERC20(address(new ERC20Mock("Democracy Token", "DDT")));
        nftMembership = new NFTMembershipMock();
        treasury = new TreasuryMock();

        hybridVoting = new HybridVoting(
            address(participationToken),
            address(democracyToken),
            address(nftMembership),
            allowedRoleNames,
            quadraticVotingEnabled,
            democracyVoteWeight,
            participationVoteWeight,
            address(treasury),
            quorumPercentage
        );

        hybridVotingQuadratic = new HybridVoting(
            address(participationToken),
            address(democracyToken),
            address(nftMembership),
            allowedRoleNames,
            true,
            democracyVoteWeight,
            participationVoteWeight,
            address(treasury),
            quorumPercentage
        );

        // Set initial balances
        deal(address(participationToken), voter1, 100);
        deal(address(democracyToken), voter1, 100);
        deal(address(democracyToken), voter2, 100);
        deal(address(democracyToken), voter3, 100);

        // set owner as member
        NFTMembershipMock(address(nftMembership)).setMemberType(owner, "member");

        deal(address(participationToken), address(treasury), 1000 * 10**18);

    }

    function testCreateProposal() public {
        vm.prank(owner);
        hybridVoting.createProposal(
            "Proposal1",
            "Description1",
            60,
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0)
        );

        (uint256 totalVotesPT, uint256 totalVotesDDT, uint256 timeInMinutes, uint256 creationTimestamp, uint256 transferTriggerOptionIndex, address payable transferRecipient, uint256 transferAmount, bool transferEnabled, address transferToken) = hybridVoting.getProposal(0);
        
        assertEq(timeInMinutes, 60);
        assertEq(totalVotesPT, 0);
        assertEq(totalVotesDDT, 0);
        assertEq(creationTimestamp > 0, true);
        assertEq(transferTriggerOptionIndex, 0);
        assertEq(transferRecipient, treasuryAddress);
        assertEq(transferAmount, 100);
        assertEq(transferEnabled, false);
        assertEq(transferToken, address(0));
    }

   function testVote() public {
        vm.prank(owner);
        hybridVoting.createProposal(
            "Proposal1",
            "Description1",
            60,
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0)
        );

        vm.prank(voter1);
        hybridVoting.vote(0, voter1, 0);

        (uint256 votesPT, uint256 votesDDT) = hybridVoting.getProposalOptionVotes(0, 0);
        assertEq(votesPT, 100);
        assertEq(votesDDT, 100);

        (
            uint256 totalVotesPT,
            uint256 totalVotesDDT,
            ,
            ,
            ,
            ,
            ,
            ,
            
        ) = hybridVoting.getProposal(0);
        assertEq(totalVotesPT, 100);
        assertEq(totalVotesDDT, 100);
    }


    function testAnnounceWinner() public {
        vm.prank(owner);
        hybridVoting.createProposal(
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
        hybridVoting.vote(0, voter1, 0);

        vm.warp(block.timestamp + 2 minutes);

        vm.prank(owner);
        hybridVoting.announceWinner(0);

        (uint256 winningOptionIndex, bool hasValidWinner) = hybridVoting.announceWinner(0);
        assertEq(winningOptionIndex, 0);
        assertEq(hasValidWinner, true);
    }

    function testQuadraticVoting() public {

        vm.prank(owner);
        hybridVotingQuadratic.createProposal(
            "Proposal1",
            "Description1",
            60,
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0)
        );

        vm.prank(voter1);
        hybridVotingQuadratic.vote(0, voter1, 0);

        (uint256 votesPT, uint256 votesDDT) = hybridVotingQuadratic.getProposalOptionVotes(0, 0);
        
        // square root of 100 is 10
        uint256 expectedQuadraticVotes = 10;
        assertEq(votesPT, expectedQuadraticVotes);
        assertEq(votesDDT, 100);

        (uint256 totalVotesPT, uint256 totalVotesDDT,,,,,,,) = hybridVotingQuadratic.getProposal(0);
        assertEq(totalVotesPT, expectedQuadraticVotes);
        assertEq(totalVotesDDT, 100);
    }
    // function to test the hybrid voting calculations in scenrrio where both PT and DDT are used and option 0 barely wins
    function testHybridVotingCalculations() public {

        // Create a proposal
        vm.prank(owner);
        hybridVoting.createProposal(
            "Proposal1",
            "Description1",
            1,
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0)
        );

        // Vote on the proposal
        vm.prank(voter1);
        hybridVoting.vote(0, voter1, 0);
        vm.prank(voter2);
        hybridVoting.vote(0, voter2, 1);
        vm.prank(voter3);
        hybridVoting.vote(0, voter3, 1);

        // Get the votes for the option
        (uint256 votesPT, uint256 votesDDT) = hybridVoting.getProposalOptionVotes(0, 0);

        // Assert the votes
        assertEq(votesPT, 100);
        assertEq(votesDDT, 100);

        (uint256 votesPT_1, uint256 votesDDT_1) = hybridVoting.getProposalOptionVotes(0, 1);
        assertEq(votesPT_1, 0);
        assertEq(votesDDT_1, 200);

        // Get the total votes for the proposal
        (
            uint256 totalVotesPT,
            uint256 totalVotesDDT,
            ,
            ,
            ,
            ,
            ,
            ,
            
        ) = hybridVoting.getProposal(0);

        // Assert the total votes
        assertEq(totalVotesPT, 100);
        assertEq(totalVotesDDT, 300);

         vm.warp(block.timestamp + 2 minutes);

        // Announce the winner
        hybridVoting.announceWinner(0);

        (uint256 winningOptionIndex, bool hasValidWinner) = hybridVoting.announceWinner(0);
        assertEq(winningOptionIndex, 0);
        assertEq(hasValidWinner, true);

    }
    // test non member cant create proposal
    function testNonMemberCannotCreateProposal() public {
        address nonMember = address(6); // Address that is not set as a member
        vm.prank(nonMember); // Use non-member account to call the function

        vm.expectRevert("Not authorized to create proposal"); // Expect revert with the specified error message

        hybridVoting.createProposal(
            "Proposal1",
            "Description1",
            60,
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0)
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

contract NFTMembershipMock is INFTMembership3 {
    mapping(address => string) public memberType;

    function checkMemberTypeByAddress(address user) external view returns (string memory) {
        return memberType[user];
    }

    function setMemberType(address user, string memory _type) external {
        memberType[user] = _type;
    }
}

contract TreasuryMock is ITreasury2 {
    function sendTokens(address _token, address _to, uint256 _amount) external {
        ERC20Mock(_token).transfer(_to, _amount);
    }

    function withdrawEther(address payable _to, uint256 _amount) external {
        _to.transfer(_amount);
    }
}
