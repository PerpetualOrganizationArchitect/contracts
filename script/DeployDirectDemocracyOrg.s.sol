// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/MasterDeployFactory.sol";

contract DeployDirectDemocracyOrg {
    MasterFactory masterFactory;

    function run(address _masterFactory, bool electionEnabled) external returns (address) {
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
            contractNames: new string[](electionEnabled ? 8 : 7), // Adjust length to match deployed contracts
            quorumPercentageDD: 50,
            quorumPercentagePV: 0,
            username: "testuser",
            electionEnabled: electionEnabled
        });

        // Setting member type names
        params.memberTypeNames[0] = "Default";
        params.memberTypeNames[1] = "Executive";

        // Setting executive permission names
        params.executivePermissionNames[0] = "Executive";

        // Setting contract names for actually deployed contracts
        params.contractNames[0] = "NFTMembership";
        params.contractNames[1] = "DirectDemocracyToken";
        params.contractNames[2] = "ParticipationToken";
        params.contractNames[3] = "Treasury";
        params.contractNames[4] = "DirectDemocracyVoting";
        params.contractNames[5] = "TaskManager";
        params.contractNames[6] = "QuickJoin";

        // Add ElectionContract if electionEnabled is true
        if (electionEnabled) {
            params.contractNames[7] = "ElectionContract";
        }

        // Deploy the organization and return the registry address
        address registryAddress = masterFactory.deployAll(params);
        return registryAddress;
    }
}
