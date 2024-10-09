// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/DirectDemocracyVotingFactory.sol";
import "../../src/DirectDemocracyTokenFactory.sol";
import "../../src/ParticipationVotingFactory.sol";
import "../../src/ParticipationTokenFactory.sol";
import "../../src/ParticipationVotingFactory.sol";
import "../../src/TreasuryFactory.sol";
import "../../src/MembershipNFTFactory.sol";
import "../../src/RegistryFactory.sol";
import "../../src/TaskManagerFactory.sol";
import "../../src/QuickJoinFactory.sol";
import "../../src/MasterDeployFactory.sol";
import "../../src/UniversalAccountRegistry.sol";
import "../../src/ParticipationVoting.sol";
import "../../src/Registry.sol";
import "../../src/ElectionContract.sol";
import "../../src/MembershipNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DeployMasterFactory} from "../../script/DeployMasterFactory.s.sol";
import {DeployDirectDemocracyOrg} from "../../script/DeployDirectDemocracyOrg.s.sol";
import {DeployParticipationOrg} from "../../script/DeployParticipationOrg.s.sol";
import {DeployParticipationOrg} from "../../script/DeployParticipationOrg.s.sol";

contract MockParticipationToken2 is IParticipationToken2 {
    mapping(address => uint256) public balances;

    function mint(address to, uint256 amount) external override {
        balances[to] += amount;
    }

    function totalSupply() external view override returns (uint256) {
        return 0;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return false;
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return 0;
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return false;
    }
}

contract MockNFTMembership11 is INFTMembership11 {
    mapping(address => string) public memberTypes;
    mapping(address => bool) public executives;

    function checkMemberTypeByAddress(
        address user
    ) external view override returns (string memory) {
        return memberTypes[user];
    }

    function checkIsExecutive(
        address user
    ) external view override returns (bool) {
        return executives[user];
    }

    function setMemberType(address user, string memory memberType) external {
        memberTypes[user] = memberType;
    }

    function setExecutive(address user, bool isExec) external {
        executives[user] = isExec;
    }
}

interface IElectionContract {
    struct Candidate {
        address candidateAddress;
        string candidateName;
    }

    function votingContract() external view returns (address);
    function createElection(
        uint256 _proposalId
    ) external returns (uint256, uint256);
    function addCandidate(
        uint256 proposalId,
        address _candidateAddress,
        string memory _candidateName
    ) external;
    function getElectionDetails(
        uint256 electionId
    ) external view returns (bool, uint256, bool);
    function getCandidates(
        uint256 electionId
    ) external view returns (Candidate[] memory);
    function concludeElection(
        uint256 proposalId,
        uint256 winningOption
    ) external;
}

contract ParticipationOrgTest is Test {
    MasterFactory masterFactory;
    ParticipationVoting participationVoting;
    address participationVotingRegistryAddress;

    function setUp() public {
        DeployMasterFactory deployMasterFactory = new DeployMasterFactory();
        address masterFactoryAddress = deployMasterFactory.run();
        masterFactory = MasterFactory(masterFactoryAddress);
    }

    /**
     * @dev test Participation Organization with 2 test configurations
     * With the Election Hub enabled and disabled. This feature controls voting processes, election events, and governance mechanisms.
     * With the Education Hub enabled and disabled. This module is responsible for guiding users through the learning curve of DAO operations and governance.
     */

    /// @dev test with Election Hub
    function testParticipationElectionHub() public {
        //Deploy ParticipationOrg with Election Hub
        DeployParticipationOrg deployParticipationOrg = new DeployParticipationOrg();
        participationVotingRegistryAddress = deployParticipationOrg.run(
            address(masterFactory),
            true,
            false
        );
        Registry registry = Registry(participationVotingRegistryAddress);
        address electionContractAddress = registry.getContractAddress(
            "ElectionContract"
        );

        address votingContractAddress = IElectionContract(
            electionContractAddress
        ).votingContract();
        address nftMembership = registry.getContractAddress("NFTMembership");

        //Election Creation
        vm.prank(votingContractAddress);
        (uint256 electionId, uint256 proposalId) = IElectionContract(
            electionContractAddress
        ).createElection(1);

        assertEq(electionId, 0);
        assertEq(proposalId, 1);

        address candidate1 = address(0xDEAD);
        address candidate2 = address(0xBEEF);
        address candidate3 = address(0xFEED);
        // Add Candidates
        vm.prank(votingContractAddress);
        IElectionContract(electionContractAddress).addCandidate(
            1,
            candidate1,
            "Candidate 1"
        );

        vm.prank(votingContractAddress);
        IElectionContract(electionContractAddress).addCandidate(
            1,
            candidate2,
            "Candidate 2"
        );

        vm.prank(votingContractAddress);
        IElectionContract(electionContractAddress).addCandidate(
            1,
            candidate3,
            "Candidate 3"
        );

        // Conclude Election
        vm.prank(votingContractAddress);
        IElectionContract(electionContractAddress).concludeElection(1, 2);

        // Verify Results
        (
            bool isActive,
            uint256 winningCandidateIndex,
            bool hasValidWinner
        ) = IElectionContract(electionContractAddress).getElectionDetails(
                electionId
            );
        assertFalse(isActive);
        assertTrue(hasValidWinner);
        assertEq(winningCandidateIndex, 2);

        // Verify Candidates
        IElectionContract.Candidate[] memory candidates = IElectionContract(
            electionContractAddress
        ).getCandidates(electionId);
        assertEq(candidates.length, 3);
        assertEq(candidates[0].candidateAddress, candidate1);
        assertEq(candidates[1].candidateAddress, candidate2);
        assertEq(candidates[2].candidateAddress, candidate3);

        // Check that the NFT was minted for the winning candidate
        assertEq(
            INFTMembership11(nftMembership).checkMemberTypeByAddress(
                candidate3
            ),
            "Executive"
        );
    }

    /// @dev test with Eduction Hub
    function testParticipationEducationHub() public {
        //Deploy ParticipationOrg with Education Hub
        DeployParticipationOrg deployParticipationOrg = new DeployParticipationOrg();
        participationVotingRegistryAddress = deployParticipationOrg.run(
            address(masterFactory),
            false,
            true
        );

        EducationHub educationHub;
        MockParticipationToken2 token;
        MockNFTMembership11 nftMembership;

        Registry registry = Registry(participationVotingRegistryAddress);
        address owner = registry.getContractAddress("EducationHub");
        address executive = address(2);
        address member = address(3);
        address nonMember = address(4);

        token = new MockParticipationToken2();
        nftMembership = new MockNFTMembership11();

        // Set up roles
        nftMembership.setMemberType(member, "Member");
        nftMembership.setExecutive(executive, true);

        educationHub = new EducationHub(address(token), address(nftMembership));

        //test create module
        vm.prank(executive);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);

        (
            uint256 id,
            string memory name,
            string memory ipfsHash,
            bool exists,
            uint256 payout,
            uint8 correctAnswer
        ) = educationHub.modules(0);
        assertEq(id, 0);
        assertEq(name, "Intro to DAO");
        assertEq(ipfsHash, "ipfsHash1");
        assertTrue(exists);
        assertEq(payout, 100);
        assertEq(correctAnswer, 1);

        //test complete module
        // Create a module as an executive
        vm.prank(executive);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);

        // Complete the module as a member
        vm.prank(member);
        educationHub.completeModule(0, 1);

        assertEq(token.balanceOf(member), 100);
        bool completed = educationHub.completedModules(member, 0);
        assertTrue(completed);

        //test remove module
        // Create a module as an executive
        vm.prank(executive);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);

        // Remove the module as an execustive
        vm.prank(executive);
        educationHub.removeModule(0);

        (, , , bool moduleExists, , ) = educationHub.modules(0);
        assertFalse(moduleExists);
    }
}
