// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/MasterDeployFactory.sol";

contract DeployHybridOrg {
    function run(address _masterFactory, bool electionEnabled) external returns (address) {
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
            contractNames: new string[](electionEnabled ? 9 : 8),
            quorumPercentageDD: 50,
            quorumPercentagePV: 50,
            username: "testuser",
            electionEnabled: electionEnabled
        });

        // Setting member type names
        params.memberTypeNames[0] = "Default";
        params.memberTypeNames[1] = "Executive";

        // Setting executive permission names
        params.executivePermissionNames[0] = "Executive";

        // Setting contract names
        params.contractNames[0] = "NFTMembership";
        params.contractNames[1] = "DirectDemocracyToken";
        params.contractNames[2] = "ParticipationToken";
        params.contractNames[3] = "Treasury";
        params.contractNames[4] = "DirectDemocracyVoting";
        params.contractNames[5] = "HybridVoting";
        params.contractNames[6] = "TaskManager";
        params.contractNames[7] = "QuickJoin";

        // Add ElectionContract if electionEnabled is true
        if (electionEnabled) {
            params.contractNames[8] = "ElectionContract";
        }

        MasterFactory masterFactory = MasterFactory(_masterFactory);
        address registryAddress = masterFactory.deployAll(params);
        return registryAddress;
    }
}
