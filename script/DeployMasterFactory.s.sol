// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
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

contract DeployMasterFactory is Script {
    function run() external returns (address masterFactoryAddress) {
        vm.startBroadcast();

        AccountManager accountManager = new AccountManager();
        DirectDemocracyVotingFactory directDemocracyVotingFactory = new DirectDemocracyVotingFactory();
        DirectDemocracyTokenFactory directDemocracyTokenFactory = new DirectDemocracyTokenFactory();
        HybridVotingFactory hybridVotingFactory = new HybridVotingFactory();
        ParticipationTokenFactory participationTokenFactory = new ParticipationTokenFactory();
        ParticipationVotingFactory participationVotingFactory = new ParticipationVotingFactory();
        TreasuryFactory treasuryFactory = new TreasuryFactory();
        NFTMembershipFactory nftMembershipFactory = new NFTMembershipFactory();
        RegistryFactory registryFactory = new RegistryFactory();
        TaskManagerFactory taskManagerFactory = new TaskManagerFactory();
        QuickJoinFactory quickJoinFactory = new QuickJoinFactory();

        MasterFactory masterFactory = new MasterFactory(
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
            address(accountManager)
        );

        vm.stopBroadcast();

        // Return the addresses
        return (address(masterFactory));
    }
}
