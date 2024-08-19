// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

interface INFTMembership {
    function mintNFT(address recipient, string memory memberTypeName) external;
}

contract ElectionContract {
    INFTMembership public nftMembership;
    address public votingContract;
    bool public electionEnabled;

    struct Candidate {
        address candidateAddress;
        string candidateName;
    }

    struct Election {
        bool isActive;
        uint256 winningCandidateIndex;
        bool hasValidWinner;
        Candidate[] candidates;
    }

    Election[] public elections;

    event ElectionCreated(uint256 indexed electionId);
    event CandidateAdded(uint256 indexed electionId, uint256 candidateIndex, address candidateAddress, string candidateName);
    event ElectionConcluded(uint256 indexed electionId, uint256 winningCandidateIndex, bool hasValidWinner);

    modifier onlyVotingContract() {
        require(msg.sender == votingContract, "Only voting contract can call this function");
        _;
    }

    constructor(address _nftMembership, address _votingContractAddress) {
        nftMembership = INFTMembership(_nftMembership);
        votingContract = _votingContractAddress;
    }

    function createElection(
        uint256 _electionId
    ) external onlyVotingContract returns (uint256) {

        Election storage newElection = elections[_electionId];
        newElection.isActive = true;

        emit ElectionCreated(_electionId);
        return _electionId;
    }

    function addCandidate(uint256 electionId, address _candidateAddress, string memory _candidateName) external onlyVotingContract {
        require(electionId < elections.length, "Invalid election ID");
        require(elections[electionId].isActive, "Election is not active");

        elections[electionId].candidates.push(Candidate(_candidateAddress, _candidateName));
        emit CandidateAdded(electionId, elections[electionId].candidates.length - 1, _candidateAddress, _candidateName);
    }

    function concludeElection(uint256 electionId, uint256 winningOption) external onlyVotingContract {
        require(electionId < elections.length, "Invalid election ID");
        require(elections[electionId].isActive, "Election is already concluded");

        elections[electionId].isActive = false;
        elections[electionId].winningCandidateIndex = winningOption;
        elections[electionId].hasValidWinner = true;

        // Mint NFT to the winning candidate
        nftMembership.mintNFT(elections[electionId].candidates[winningOption].candidateAddress, "Executive");

        emit ElectionConcluded(electionId, winningOption, true);

    }

    function getElectionDetails(uint256 electionId) external view returns (bool, uint256, bool) {
        require(electionId < elections.length, "Invalid election ID");
        Election storage election = elections[electionId];
        return (
            election.isActive,
            election.winningCandidateIndex,
            election.hasValidWinner
        );
    }

    function getCandidates(uint256 electionId) external view returns (Candidate[] memory) {
        require(electionId < elections.length, "Invalid election ID");
        return elections[electionId].candidates;
    }
}
