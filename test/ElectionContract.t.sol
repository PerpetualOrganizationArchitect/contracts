// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ElectionContract.sol";
import "../src/MembershipNFT.sol";

contract ElectionContractTest is Test {
    ElectionContract public electionContract;
    NFTMembership public nftMembership;
    address public votingContractAddress = address(0xBEEF);
    address public candidate1 = address(0xDEAD);
    address public candidate2 = address(0xBEEF);
    address public candidate3 = address(0xFEED);

    function setUp() public {
        string[] memory memberTypeNames = new string[](2);
        memberTypeNames[0] = "Basic";
        memberTypeNames[1] = "Executive";

        string[] memory executiveRoleNames = new string[](1);
        executiveRoleNames[0] = "Executive";
        nftMembership = new NFTMembership(
            memberTypeNames,
            executiveRoleNames,
            "defaultImageURL"
        );
       
        electionContract = new ElectionContract(address(nftMembership), votingContractAddress);
        nftMembership.setElectionContract(address(electionContract));
    }

    function testCreateElection() public {
        // Simulate calling from the voting contract
        vm.prank(votingContractAddress);
        (uint256 electionId, uint256 proposalId) = electionContract.createElection(1);

        assertEq(electionId, 0);
        assertEq(proposalId, 1);

        // Check that the election was created correctly
        (bool isActive, , bool hasValidWinner) = electionContract.getElectionDetails(electionId);
        assertTrue(isActive);
        assertFalse(hasValidWinner);
    }

    function testAddCandidate() public {
        vm.prank(votingContractAddress);
        (uint256 electionId, ) = electionContract.createElection(1);

        vm.prank(votingContractAddress);
        electionContract.addCandidate(1, candidate1, "Candidate 1");

        ElectionContract.Candidate[] memory candidates = electionContract.getCandidates(electionId);
        assertEq(candidates.length, 1);
        assertEq(candidates[0].candidateAddress, candidate1);
        assertEq(candidates[0].candidateName, "Candidate 1");
    }

    function testConcludeElection() public {
        vm.prank(votingContractAddress);
        (uint256 electionId, ) = electionContract.createElection(1);

        vm.prank(votingContractAddress);
        electionContract.addCandidate(1, candidate1, "Candidate 1");

        vm.prank(votingContractAddress);
        electionContract.concludeElection(1, 0);

        (bool isActive, uint256 winningCandidateIndex, bool hasValidWinner) = electionContract.getElectionDetails(electionId);
        assertFalse(isActive);
        assertTrue(hasValidWinner);
        assertEq(winningCandidateIndex, 0);

        // Check that the NFT was minted for the winning candidate
        assertEq(nftMembership.checkMemberTypeByAddress(candidate1), "Executive");
    }

    function testFailAddCandidateWhenElectionIsConcluded() public {
        vm.prank(votingContractAddress);
        (uint256 electionId, ) = electionContract.createElection(1);

        vm.prank(votingContractAddress);
        electionContract.addCandidate(1, candidate1, "Candidate 1");

        vm.prank(votingContractAddress);
        electionContract.concludeElection(1, 0);

        // Adding a candidate after the election is concluded should fail
        vm.expectRevert("Election is not active");
        vm.prank(votingContractAddress);
        electionContract.addCandidate(1, candidate2, "Candidate 2");
    }

    function testFailConcludeElectionWhenInvalidWinningOption() public {
        vm.prank(votingContractAddress);
        (uint256 electionId, ) = electionContract.createElection(1);

        vm.prank(votingContractAddress);
        electionContract.addCandidate(1, candidate1, "Candidate 1");

        // Attempting to conclude an election with an invalid winning option should fail
        vm.expectRevert("Invalid winning option");
        vm.prank(votingContractAddress);
        electionContract.concludeElection(1, 0);
    }

    function testFailAddCandidateByNonVotingContract() public {
        // Attempting to add a candidate by a non-voting contract should fail
        vm.prank(address(0xBEEF));
        vm.expectRevert("Only voting contract can call this function");
        electionContract.addCandidate(1, candidate1, "Candidate 1");
    }

    function testFailConcludeElectionByNonVotingContract() public {
        // Attempting to conclude an election by a non-voting contract should fail
        vm.prank(address(0xBEEF));
        vm.expectRevert("Only voting contract can call this function");
        electionContract.concludeElection(1, 0);
    }

    function testElectionLifecycle() public {
        // Election Creation
        vm.prank(votingContractAddress);
        (uint256 electionId, uint256 proposalId) = electionContract.createElection(1);

        assertEq(electionId, 0);
        assertEq(proposalId, 1);

        // Add Candidates
        vm.prank(votingContractAddress);
        electionContract.addCandidate(1, candidate1, "Candidate 1");

        vm.prank(votingContractAddress);
        electionContract.addCandidate(1, candidate2, "Candidate 2");

        vm.prank(votingContractAddress);
        electionContract.addCandidate(1, candidate3, "Candidate 3");

        // Conclude Election
        vm.prank(votingContractAddress);
        electionContract.concludeElection(1, 2);

        // Verify Results
        (bool isActive, uint256 winningCandidateIndex, bool hasValidWinner) = electionContract.getElectionDetails(electionId);
        assertFalse(isActive);
        assertTrue(hasValidWinner);
        assertEq(winningCandidateIndex, 2);

        // Verify Candidates
        ElectionContract.Candidate[] memory candidates = electionContract.getCandidates(electionId);
        assertEq(candidates.length, 3);
        assertEq(candidates[0].candidateAddress, candidate1);
        assertEq(candidates[1].candidateAddress, candidate2);
        assertEq(candidates[2].candidateAddress, candidate3);

        // Check that the NFT was minted for the winning candidate
        assertEq(nftMembership.checkMemberTypeByAddress(candidate3), "Executive");
    }

    function testElectionWithMultipleProposals() public {
        // Create first election
        vm.prank(votingContractAddress);
        (uint256 electionId1, uint256 proposalId1) = electionContract.createElection(1);

        vm.prank(votingContractAddress);
        electionContract.addCandidate(1, candidate1, "Candidate 1");

        // Create second election
        vm.prank(votingContractAddress);
        (uint256 electionId2, uint256 proposalId2) = electionContract.createElection(2);

        vm.prank(votingContractAddress);
        electionContract.addCandidate(2, candidate2, "Candidate 2");

        // Conclude first election
        vm.prank(votingContractAddress);
        electionContract.concludeElection(1, 0);

        // Conclude second election
        vm.prank(votingContractAddress);
        electionContract.concludeElection(2, 0);

        // Verify first election results
        (bool isActive1, uint256 winningCandidateIndex1, bool hasValidWinner1) = electionContract.getElectionDetails(electionId1);
        assertFalse(isActive1);
        assertTrue(hasValidWinner1);
        assertEq(winningCandidateIndex1, 0);

        // Verify second election results
        (bool isActive2, uint256 winningCandidateIndex2, bool hasValidWinner2) = electionContract.getElectionDetails(electionId2);
        assertFalse(isActive2);
        assertTrue(hasValidWinner2);
        assertEq(winningCandidateIndex2, 0);
    }
}
