// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
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

contract MasterFactoryTest is Test {
    DirectDemocracyVotingFactory directDemocracyVotingFactory;
    DirectDemocracyTokenFactory directDemocracyTokenFactory;
    HybridVotingFactory hybridVotingFactory;
    ParticipationTokenFactory participationTokenFactory;
    ParticipationVotingFactory participationVotingFactory;
    TreasuryFactory treasuryFactory;
    NFTMembershipFactory nftMembershipFactory;
    RegistryFactory registryFactory;
    TaskManagerFactory taskManagerFactory;
    QuickJoinFactory quickJoinFactory;
    AccountManager accountManager;
    MasterFactory masterFactory;

    function setUp() public {
        // Deploying the AccountManager contract first
        accountManager = new AccountManager();
        address accountManagerAddress = address(accountManager);

        directDemocracyVotingFactory = new DirectDemocracyVotingFactory();
        directDemocracyTokenFactory = new DirectDemocracyTokenFactory();
        hybridVotingFactory = new HybridVotingFactory();
        participationTokenFactory = new ParticipationTokenFactory();
        participationVotingFactory = new ParticipationVotingFactory();
        treasuryFactory = new TreasuryFactory();
        nftMembershipFactory = new NFTMembershipFactory();
        registryFactory = new RegistryFactory();
        taskManagerFactory = new TaskManagerFactory();
        quickJoinFactory = new QuickJoinFactory();

        masterFactory = new MasterFactory(
            address(directDemocracyTokenFactory),
            address(directDemocracyVotingFactory),
            address(hybridVotingFactory),
            address(participationTokenFactory),
            address(participationVotingFactory),
            address(treasuryFactory),
            address(nftMembershipFactory),
            address(registryFactory),
            address(taskManagerFactory),
            address(quickJoinFactory),
            accountManagerAddress
        );
    }

    function testDeployAll() public {
        MasterFactory.DeployParams memory params = MasterFactory.DeployParams({
            memberTypeNames: new string ,
            executivePermissionNames: new string ,
            POname: "TestPO",
            quadraticVotingEnabled: true,
            democracyVoteWeight: 1,
            participationVoteWeight: 1,
            hybridVotingEnabled: true,
            participationVotingEnabled: true,
            logoURL: "https://example.com/logo.png",
            infoIPFSHash: "QmTestHash",
            votingControlType: "Hybrid",
            contractNames: new string ,
            quorumPercentageDD: 50,
            quorumPercentagePV: 50,
            username: "testuser"
        });

        params.memberTypeNames[0] = "MemberType1";
        params.memberTypeNames[1] = "MemberType2";
        params.executivePermissionNames[0] = "Permission1";
        params.executivePermissionNames[1] = "Permission2";
        params.contractNames[0] = "NFTMembership";
        params.contractNames[1] = "DirectDemocracyToken";
        params.contractNames[2] = "ParticipationToken";
        params.contractNames[3] = "Treasury";
        params.contractNames[4] = "DirectDemocracyVoting";
        params.contractNames[5] = "HybridVoting";
        params.contractNames[6] = "TaskManager";
        params.contractNames[7] = "QuickJoin";

        vm.recordLogs();
        masterFactory.deployAll(params);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertEq(logs.length, 1);
        assertEq(logs[0].topics[0], keccak256("DeployParamsLog(string[],string[],string,bool,uint256,uint256,bool,bool,string,string,string[])"));
        assertEq(logs[0].data.length, abi.encode(params.memberTypeNames, params.executivePermissionNames, params.POname, params.quadraticVotingEnabled, params.democracyVoteWeight, params.participationVoteWeight, params.hybridVotingEnabled, params.participationVotingEnabled, params.logoURL, params.votingControlType, params.contractNames).length);
    }
}
