// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/MasterDeployFactory.sol";

contract DeployParticipationOrg {
    function run(
        address _masterFactory,
        bool electionEnabled,
        bool educationHubEnabled // Added educationHubEnabled parameter
    ) external returns (address) {
        // Adjust the length of the contractNames array based on the enabled flags
        uint256 contractCount = 8; // Default count
        if (electionEnabled) contractCount++;
        if (educationHubEnabled) contractCount++;

        MasterFactory.DeployParams memory params = MasterFactory.DeployParams({
            memberTypeNames: new string[](2),
            executivePermissionNames: new string[](1),
            POname: "ParticipationVotingPO",
            quadraticVotingEnabled: false,
            democracyVoteWeight: 0,
            participationVoteWeight: 100,
            hybridVotingEnabled: false,
            participationVotingEnabled: true,
            logoURL: "QmLogoHash",
            infoIPFSHash: "QmTestHash",
            votingControlType: "Participation",
            contractNames: new string[](contractCount),
            quorumPercentageDD: 0,
            quorumPercentagePV: 50,
            username: "testuser",
            electionEnabled: electionEnabled,
            educationHubEnabled: educationHubEnabled
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
        params.contractNames[5] = "ParticipationVoting";
        params.contractNames[6] = "TaskManager";
        params.contractNames[7] = "QuickJoin";

        // Add ElectionContract if electionEnabled is true
        uint256 nextIndex = 8;
        if (electionEnabled) {
            params.contractNames[nextIndex++] = "ElectionContract";
        }

        // Add EducationHub if educationHubEnabled is true
        if (educationHubEnabled) {
            params.contractNames[nextIndex] = "EducationHub";
        }

        MasterFactory masterFactory = MasterFactory(_masterFactory);
        address registryAddress = masterFactory.deployAll(params);
        return registryAddress;
    }
}
