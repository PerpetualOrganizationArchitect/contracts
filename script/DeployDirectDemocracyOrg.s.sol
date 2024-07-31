// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/MasterDeployFactory.sol";

contract DeployDirectDemocracyOrg {
    MasterFactory masterFactory;

    function run(address _masterFactory) external returns (address) {
        masterFactory = MasterFactory(_masterFactory);
        MasterFactory.DeployParams memory params = MasterFactory.DeployParams({
            memberTypeNames: new string[](2),
            executivePermissionNames: new string[](1),
            POname: "DirectDemocracyPO",
            quadraticVotingEnabled: false,
            democracyVoteWeight: 100,
            participationVoteWeight: 0,
            hybridVotingEnabled: false,
            participationVotingEnabled: false,
            logoURL: "QmLogoHash",
            infoIPFSHash: "QmTestHash",
            votingControlType: "DirectDemocracy",
            contractNames: new string[](8),
            quorumPercentageDD: 50,
            quorumPercentagePV: 0,
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

        address registryAddress = masterFactory.deployAll(params);
        return registryAddress;
    }
}
