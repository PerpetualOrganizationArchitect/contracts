// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DirectDemocracyVoting.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/ElectionContract.sol";

contract DirectDemocracyVotingExhaustiveTest is Test {
    DirectDemocracyVoting public directDemocracyVoting;
    IERC20 public democracyToken;
    INFTMembership2 public nftMembership;
    ITreasury public treasury;
    ElectionContract public elections;

    address public owner = address(1);
    address public voter1 = address(2);
    address public voter2 = address(3);
    address public nonMember = address(4);
    address public treasuryAddress = address(5);

    uint256 public quorumPercentage = 51;
    string[] public allowedRoleNames = ["Executive"];
    string[] public optionNames = ["Option1", "Option2", "Option3"];
    address[] public candidateAddresses;
    string[] public candidateNames;

    function setUp() public {
        democracyToken = IERC20(address(new ERC20Mock("Democracy Token", "DDT")));
        nftMembership = new NFTMembershipMock();
        treasury = new TreasuryMock();

        directDemocracyVoting = new DirectDemocracyVoting(
            address(democracyToken), address(nftMembership), allowedRoleNames, address(treasury), quorumPercentage
        );

        elections = new ElectionContract(address(nftMembership), address(directDemocracyVoting));
        directDemocracyVoting.setElectionsContract(address(elections));

        // Set initial balances
        deal(address(democracyToken), voter1, 100);
        deal(address(democracyToken), voter2, 100);

        // Set member types
        NFTMembershipMock(address(nftMembership)).setMemberType(owner, "Executive");
        NFTMembershipMock(address(nftMembership)).setMemberType(voter1, "Executive");

        candidateAddresses.push(voter1);
        candidateAddresses.push(voter2);

        candidateNames.push("Candidate 1");
        candidateNames.push("Candidate 2");
    }

    function testNonMemberCannotCreateProposal() public {
        vm.prank(nonMember); // Use non-member account to call the function

        vm.expectRevert("Not authorized to create proposal");
        directDemocracyVoting.createProposal(
            "Proposal1",
            "Description1",
            60,
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0),
            false,
            candidateAddresses,
            candidateNames
        );
    }

    function testVoteRequiresBalance() public {
        vm.prank(owner);
        directDemocracyVoting.createProposal(
            "Proposal1",
            "Description1",
            60,
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0),
            false,
            candidateAddresses,
            candidateNames
        );

        // Set voter2 balance to zero
        deal(address(democracyToken), voter2, 0);

        uint256[] memory optionIndices = new uint256[](2);
        uint256[] memory weights = new uint256[](2);
        optionIndices[0] = 0;
        optionIndices[1] = 1;
        weights[0] = 70;
        weights[1] = 30;

        vm.prank(voter2);
        vm.expectRevert("No democracy tokens");
        directDemocracyVoting.vote(0, voter2, optionIndices, weights);
    }

    function testVoteFailsWithImproperWeights() public {
        vm.prank(owner);
        directDemocracyVoting.createProposal(
            "Proposal1",
            "Description1",
            60,
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0),
            false,
            candidateAddresses,
            candidateNames
        );

        // Voter1 tries to vote with improper weights that do not sum to 100
        uint256[] memory optionIndices = new uint256[](2);
        uint256[] memory improperWeights = new uint256[](2);
        optionIndices[0] = 0;
        optionIndices[1] = 1;
        improperWeights[0] = 70;
        improperWeights[1] = 40; // Sum is 110, invalid

        vm.prank(voter1);
        vm.expectRevert("Total weight must be 100");
        directDemocracyVoting.vote(0, voter1, optionIndices, improperWeights);
    }

    function testCannotVoteTwice() public {
        vm.prank(owner);
        directDemocracyVoting.createProposal(
            "Proposal1",
            "Description1",
            60,
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0),
            false,
            candidateAddresses,
            candidateNames
        );

        // First vote
        uint256[] memory optionIndices = new uint256[](2);
        uint256[] memory weights = new uint256[](2);
        optionIndices[0] = 0;
        optionIndices[1] = 1;
        weights[0] = 70;
        weights[1] = 30;

        vm.prank(voter1);
        directDemocracyVoting.vote(0, voter1, optionIndices, weights);

        // Try to vote again
        vm.prank(voter1);
        vm.expectRevert("Already voted");
        directDemocracyVoting.vote(0, voter1, optionIndices, weights);
    }

    function testCannotVoteAfterExpiration() public {
        vm.prank(owner);
        directDemocracyVoting.createProposal(
            "Proposal1",
            "Description1",
            1, // 1 minute
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0),
            false,
            candidateAddresses,
            candidateNames
        );

        // Warp time to after expiration
        vm.warp(block.timestamp + 2 minutes);

        uint256[] memory optionIndices = new uint256[](2);
        uint256[] memory weights = new uint256[](2);
        optionIndices[0] = 0;
        optionIndices[1] = 1;
        weights[0] = 70;
        weights[1] = 30;

        vm.prank(voter1);
        vm.expectRevert("Voting time expired");
        directDemocracyVoting.vote(0, voter1, optionIndices, weights);
    }

    function testAnnounceWinnerWithNoQuorum() public {
        vm.prank(owner);
        directDemocracyVoting.createProposal(
            "Proposal1",
            "Description1",
            1, // 1 minute
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0),
            false,
            candidateAddresses,
            candidateNames
        );

        // Voter1 votes 60% for Option1 and 40% for Option2
        uint256[] memory optionIndices = new uint256[](2);
        uint256[] memory weights = new uint256[](2);
        optionIndices[0] = 0;
        optionIndices[1] = 1;
        weights[0] = 50;
        weights[1] = 50;

        vm.prank(voter1);
        directDemocracyVoting.vote(0, voter1, optionIndices, weights);

        // Warp to after the proposal expires
        vm.warp(block.timestamp + 2 minutes);

        // Announce winner (should fail due to not meeting quorum)
        vm.prank(owner);
        (uint256 winningOptionIndex, bool hasValidWinner) = directDemocracyVoting.announceWinner(0);

        assertEq(winningOptionIndex, 0); // Option1 should be the winner
        assertFalse(hasValidWinner, "Winner should be invalid due to quorum not being met");
    }

    function testAnnounceWinnerWithQuorum() public {
        vm.prank(owner);
        directDemocracyVoting.createProposal(
            "Proposal1",
            "Description1",
            1, // 1 minute
            optionNames,
            0,
            payable(treasuryAddress),
            100,
            false,
            address(0),
            false,
            candidateAddresses,
            candidateNames
        );

        // Voter1 votes 51% for Option1 and 49% for Option2
        uint256[] memory optionIndices = new uint256[](2);
        uint256[] memory weights = new uint256[](2);
        optionIndices[0] = 0;
        optionIndices[1] = 1;
        weights[0] = 51;
        weights[1] = 49;

        vm.prank(voter1);
        directDemocracyVoting.vote(0, voter1, optionIndices, weights);

        // Voter2 votes 60% for Option2 and 40% for Option1
        uint256[] memory optionIndices2 = new uint256[](2);
        uint256[] memory weights2 = new uint256[](2);
        optionIndices2[0] = 0;
        optionIndices2[1] = 1;
        weights2[0] = 40;
        weights2[1] = 60;

        vm.prank(voter2);
        directDemocracyVoting.vote(0, voter2, optionIndices2, weights2);

        // Warp to after expiration
        vm.warp(block.timestamp + 2 minutes);

        // Announce winner (should meet quorum)
        vm.prank(owner);
        (uint256 winningOptionIndex, bool hasValidWinner) = directDemocracyVoting.announceWinner(0);

        assertEq(winningOptionIndex, 1); // Option2 should be the winner
        assertTrue(hasValidWinner, "Winner should be valid since quorum is met");
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

    function mintNFT(address _to, string memory _type) external {
        memberType[_to] = _type;
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
