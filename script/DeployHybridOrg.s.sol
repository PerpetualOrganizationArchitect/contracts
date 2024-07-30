// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/MasterDeployFactory.sol";

contract DeployHybridOrg {
    function run(address _masterFactory) external {
        MasterFactory.DeployParams memory params = MasterFactory.DeployParams({
            memberTypeNames: new string[](2),
            executivePermissionNames: new string[](1),
            POname: "HybridVotingPO",
            quadraticVotingEnabled: false,
            democracyVoteWeight: 50,
            participationVoteWeight: 50,
            hybridVotingEnabled: true,
            participationVotingEnabled: false,
            logoURL: "QmLogoHash",
            infoIPFSHash: "QmTestHash",
            votingControlType: "Hybrid",
            contractNames: new string[](8),
            quorumPercentageDD: 50,
            quorumPercentagePV: 50,
            username: "testuser"
        });

        params.memberTypeNames[0] = "Default";
        params.memberTypeNames[1] = "Executive";
        params.executivePermissionNames[0] = "Executive";
        params.contractNames[0] = "NFTMembership";
        params.contractNames[1] = "DirectDemocracyToken";
        params.contractNames[2] = "ParticipationToken";
        params.contractNames[3] = "Treasury";
        params.contractNames[4] = "DirectDemocracyVoting";
        params.contractNames[5] = "HybridVoting";
        params.contractNames[6] = "TaskManager";
        params.contractNames[7] = "QuickJoin";

        MasterFactory masterFactory = MasterFactory(_masterFactory);
        masterFactory.deployAll(params);
    }
}
