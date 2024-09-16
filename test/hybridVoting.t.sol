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
    address public voter1 = address(2); // 137 PT
    address public voter2 = address(3); // 1338 PT
    address public voter3 = address(4); // 234 PT
    address public treasuryAddress = address(5);

    uint256 public democracyVoteWeight = 73;
    uint256 public participationVoteWeight = 27;
    uint256 public quorumPercentage = 51;

    string[] public allowedRoleNames = ["member"];
    string[] public optionNames = ["Option1", "Option2"];
    bool public quadraticVotingEnabled = true;

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
            false, // Normal voting
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
            true, // Quadratic voting
            democracyVoteWeight,
            participationVoteWeight,
            address(treasury),
            quorumPercentage
        );

        // Set initial balances for participants
        deal(address(participationToken), voter1, 137); // 137 PT for voter1
        deal(address(participationToken), voter2, 1338); // 1338 PT for voter2
        deal(address(participationToken), voter3, 234); // 234 PT for voter3
        deal(address(democracyToken), voter1, 100); // 100 DDT for voter1
        deal(address(democracyToken), voter2, 100); // 500 DDT for voter2
        deal(address(democracyToken), voter3, 100); // 300 DDT for voter3

        // Set owner as member
        NFTMembershipMock(address(nftMembership)).setMemberType(owner, "member");
        deal(address(participationToken), address(treasury), 1000 * 10 ** 18);
    }

    function testCreateProposal() public {
        vm.prank(owner);
        hybridVoting.createProposal(
            "Proposal1", "Description1", 60, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );

        (
            uint256 totalVotesPT,
            uint256 totalVotesDDT,
            uint256 timeInMinutes,
            uint256 creationTimestamp,
            uint256 transferTriggerOptionIndex,
            address payable transferRecipient,
            uint256 transferAmount,
            bool transferEnabled,
            address transferToken
        ) = hybridVoting.getProposal(0);

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

    function testQuadraticWeightedVotingWithDifferentBalances() public {
        vm.prank(owner);
        hybridVotingQuadratic.createProposal(
            "Proposal1", "Description1", 60, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );

        uint256[] memory optionIndices = new uint256[](2);
        optionIndices[0] = 0;
        optionIndices[1] = 1;

        uint256[] memory weightsVoter1 = new uint256[](2);
        weightsVoter1[0] = 61; // 61% to option 0
        weightsVoter1[1] = 39; // 39% to option 1

        uint256[] memory weightsVoter2 = new uint256[](2);
        weightsVoter2[0] = 53; // 53% to option 0
        weightsVoter2[1] = 47; // 47% to option 1

        // Voter1 votes (137 PT, 100 DDT), quadratic voting applies
        vm.prank(voter1);
        hybridVotingQuadratic.vote(0, voter1, optionIndices, weightsVoter1);

        // Voter2 votes (1338 PT, 500 DDT), quadratic voting applies
        vm.prank(voter2);
        hybridVotingQuadratic.vote(0, voter2, optionIndices, weightsVoter2);

        // Verify the votes for each option
        (uint256 votesPT0, uint256 votesDDT0) = hybridVotingQuadratic.getProposalOptionVotes(0, 0);
        (uint256 votesPT1, uint256 votesDDT1) = hybridVotingQuadratic.getProposalOptionVotes(0, 1);

        // Check quadratic calculations
        uint256 expectedPTVoter1 = 11;
        uint256 expectedPTVoter2 = 36;

        console.log("Expected votes pt0: %d", (expectedPTVoter1 * 61 ) + (expectedPTVoter2 * 53));
        console.log("Expected votes pt1 %d", (expectedPTVoter1 * 39 ) + (expectedPTVoter2 * 47));

        assertEq(votesPT0, (expectedPTVoter1 * 61 ) + (expectedPTVoter2 * 53 ));
        assertEq(votesPT1, (expectedPTVoter1 * 39) + (expectedPTVoter2 * 47 ));

        assertEq(votesDDT0, (100 * 61 ) + (100 * 53 )); // Democracy tokens (no quadratic)
        assertEq(votesDDT1, (100 * 39 ) + (100 * 47 )); // Democracy tokens (no quadratic)
    }

    function testAnnounceWinner() public {
        vm.prank(owner);
        hybridVoting.createProposal(
            "Proposal1",
            "Description1",
            1,
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            true,
            address(participationToken)
        );

        uint256[] memory optionIndices = new uint256[](2);
        optionIndices[0] = 0;
        optionIndices[1] = 1;

        uint256[] memory weightsVoter1 = new uint256[](2);
        weightsVoter1[0] = 51;
        weightsVoter1[1] = 49;

        // Voter1 votes
        vm.prank(voter1);
        hybridVoting.vote(0, voter1, optionIndices, weightsVoter1);

        // Advance time to make the proposal expire
        vm.warp(block.timestamp + 2 minutes);

        // Announce the winner
        vm.prank(owner);
        (uint256 winningOptionIndex, bool hasValidWinner) = hybridVoting.announceWinner(0);
        assertEq(winningOptionIndex, 0); // Assume option 0 wins based on weights
        assertEq(hasValidWinner, true);
    }

    function testCannotCreateProposalNotAllowed() public {
        vm.prank(voter1); // voter1 is not in allowedRoles
        vm.expectRevert("Not authorized to create proposal");
        hybridVoting.createProposal(
            "Proposal1", "Description1", 60, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );
    }

    function testAnnounceWinnerQuorumNotReached() public {
        vm.prank(owner);
        hybridVoting.createProposal(
            "Proposal1", "Description1", 1, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );

        // No votes cast

        // Advance time to make the proposal expire
        vm.warp(block.timestamp + 2 minutes);

        vm.prank(owner);
        (uint256 winningOptionIndex, bool hasValidWinner) = hybridVoting.announceWinner(0);

        assertEq(hasValidWinner, false); // Quorum not reached
    }

    function testCannotAnnounceWinnerBeforeProposalExpired() public {
        vm.prank(owner);
        hybridVoting.createProposal(
            "Proposal1", "Description1", 60, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );

        vm.prank(owner);
        vm.expectRevert("Voting is not yet closed");
        hybridVoting.announceWinner(0);
    }

    function testAnnounceWinnerWithZeroTotalVotes() public {
        vm.prank(owner);
        hybridVoting.createProposal(
            "Proposal1", "Description1", 1, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );

        // No votes cast

        // Advance time to make the proposal expire
        vm.warp(block.timestamp + 2 minutes);

        vm.prank(owner);
        (uint256 winningOptionIndex, bool hasValidWinner) = hybridVoting.announceWinner(0);

        // Ensure no division by zero occurs and the function handles it
        assertEq(hasValidWinner, false);
    }



    function testLeftoverTokenDistributionWithQuadraticVoting() public {
        vm.prank(owner);
        hybridVotingQuadratic.createProposal(
            "Proposal1", "Description1", 60, optionNames, 0, payable(treasuryAddress), 100, false, address(0)
        );

        uint256[] memory optionIndices = new uint256[](2);
        optionIndices[0] = 0;
        optionIndices[1] = 1;

        uint256[] memory weights = new uint256[](2);
        weights[0] = 50; // 50% to option 0
        weights[1] = 50; // 50% to option 1

        // Voter1 votes
        vm.prank(voter1);
        hybridVotingQuadratic.vote(0, voter1, optionIndices, weights);

        // Voter2 votes
        vm.prank(voter2);
        hybridVotingQuadratic.vote(0, voter2, optionIndices, weights);

        // Check leftover token distribution after quadratic voting and rounding
        (uint256 votesPT0, uint256 votesDDT0) = hybridVotingQuadratic.getProposalOptionVotes(0, 0);
        (uint256 votesPT1, uint256 votesDDT1) = hybridVotingQuadratic.getProposalOptionVotes(0, 1);

        assertTrue(votesPT0 + votesPT1 <= sqrt(137)*100 + sqrt(1338)*100, "Leftover tokens handled correctly");
    }

    function sqrt(uint256 x) public pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
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
