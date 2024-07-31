// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/DirectDemocracyVotingFactory.sol";
import "../src/DirectDemocracyTokenFactory.sol";
import "../src/HybridVotingFactory.sol";
import "../src/ParticipationTokenFactory.sol";
import "../src/ParticipationVotingFactory.sol";
import "../src/TreasuryFactory.sol";
import "../src/MembershipNFTFactory.sol";
import "../src/RegistryFactory.sol";
import "../src/TaskManagerFactory.sol";
import "../src/QuickJoinFactory.sol";
import "../src/MasterDeployFactory.sol";
import "../src/UniversalAccountRegistry.sol";
import "../src/HybridVoting.sol";
import "../src/Registry.sol";

import {DeployMasterFactory} from "../script/DeployMasterFactory.s.sol";
import {DeployDirectDemocracyOrg} from "../script/DeployDirectDemocracyOrg.s.sol";
import {DeployParticipationOrg} from "../script/DeployParticipationOrg.s.sol";
import {DeployHybridOrg} from "../script/DeployHybridOrg.s.sol";

contract TestAllOrgTypes is Test {
    MasterFactory masterFactory;
    HybridVoting hybridVoting;
    address directDemocracyRegistryAddress;
    address participationVotingRegistryAddress;
    address hybridVotingRegistryAddress;

    function setUp() public {
        DeployMasterFactory deployMasterFactory = new DeployMasterFactory();
        address masterFactoryAddress = deployMasterFactory.run();
        masterFactory = MasterFactory(masterFactoryAddress);
    }

    function testDeployDirectDemocracy() public {
        DeployDirectDemocracyOrg deployDirectDemocracyOrg = new DeployDirectDemocracyOrg();

        directDemocracyRegistryAddress = deployDirectDemocracyOrg.run(address(masterFactory));

        checkContractAddresses(directDemocracyRegistryAddress, "DirectDemocracy");
    }

    function testDeployParticipationVoting() public {
        DeployParticipationOrg deployParticipationOrg = new DeployParticipationOrg();

        participationVotingRegistryAddress = deployParticipationOrg.run(address(masterFactory));

        checkContractAddresses(participationVotingRegistryAddress, "ParticipationVoting");
    }

    function testDeployHybridVoting() public {
        DeployHybridOrg deployHybridOrg = new DeployHybridOrg();

        hybridVotingRegistryAddress = deployHybridOrg.run(address(masterFactory));

        checkContractAddresses(hybridVotingRegistryAddress, "HybridVoting");
    }

    function checkContractAddresses(address registryAddress, string memory deploymentType) internal view {
        Registry registry = Registry(registryAddress);

        address nftMembership = registry.getContractAddress("NFTMembership");
        address directDemocracyToken = registry.getContractAddress("DirectDemocracyToken");
        address participationToken = registry.getContractAddress("ParticipationToken");
        address treasury = registry.getContractAddress("Treasury");
        address directDemocracyVoting = registry.getContractAddress("DirectDemocracyVoting");
        address hybridVotingAddress = registry.getContractAddress("HybridVoting");
        address taskManager = registry.getContractAddress("TaskManager");
        address quickJoin = registry.getContractAddress("QuickJoin");
        address participationVoting = registry.getContractAddress("ParticipationVoting");

        // Check if the contract addresses are valid based on the deployment type
        if (keccak256(abi.encodePacked(deploymentType)) == keccak256(abi.encodePacked("DirectDemocracy"))) {
            assertTrue(nftMembership != address(0), "NFTMembership address is invalid");
            assertTrue(directDemocracyToken != address(0), "DirectDemocracyToken address is invalid");
            assertTrue(treasury != address(0), "Treasury address is invalid");
            assertTrue(directDemocracyVoting != address(0), "DirectDemocracyVoting address is invalid");
            assertTrue(taskManager != address(0), "TaskManager address is invalid");
            assertTrue(quickJoin != address(0), "QuickJoin address is invalid");
            assertTrue(participationToken != address(0), "ParticipationToken address is invalid");
        } else if (keccak256(abi.encodePacked(deploymentType)) == keccak256(abi.encodePacked("ParticipationVoting"))) {
            assertTrue(nftMembership != address(0), "NFTMembership address is invalid");
            assertTrue(participationToken != address(0), "ParticipationToken address is invalid");
            assertTrue(treasury != address(0), "Treasury address is invalid");
            assertTrue(taskManager != address(0), "TaskManager address is invalid");
            assertTrue(quickJoin != address(0), "QuickJoin address is invalid");
            assertTrue(directDemocracyVoting != address(0), "DirectDemocracyVoting address is invalid");
            assertTrue(directDemocracyToken != address(0), "DirectDemocracyToken address is invalid");
            //assertTrue(participationVoting != address(0), "ParticipationVoting address is invalid");
        } else if (keccak256(abi.encodePacked(deploymentType)) == keccak256(abi.encodePacked("HybridVoting"))) {
            assertTrue(nftMembership != address(0), "NFTMembership address is invalid");
            assertTrue(directDemocracyToken != address(0), "DirectDemocracyToken address is invalid");
            assertTrue(participationToken != address(0), "ParticipationToken address is invalid");
            assertTrue(treasury != address(0), "Treasury address is invalid");
            assertTrue(hybridVotingAddress != address(0), "HybridVoting address is invalid");
            assertTrue(taskManager != address(0), "TaskManager address is invalid");
            assertTrue(quickJoin != address(0), "QuickJoin address is invalid");
            assertTrue(directDemocracyVoting != address(0), "DirectDemocracyVoting address is invalid");
        } else {
            revert("Invalid deployment type");
        }
    }
}
