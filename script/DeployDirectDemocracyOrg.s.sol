// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/MasterDeployFactory.sol";

contract DeployDirectDemocracyOrg {
    MasterFactory masterFactory;

    function run(
        address _masterFactory,
        bool electionEnabled,
        bool educationHubEnabled // Added educationHubEnabled parameter
    ) external returns (address) {
        masterFactory = MasterFactory(_masterFactory);

        // Adjust the length of the contractNames array based on the enabled flags
        uint256 contractCount = 7; // Default count
        if (electionEnabled) contractCount++;
        if (educationHubEnabled) contractCount++;

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
            contractNames: new string[](contractCount), // Adjusted length based on enabled flags
            quorumPercentageDD: 50,
            quorumPercentagePV: 0,
            username: "testuser",
            electionEnabled: electionEnabled, // Pass the electionEnabled flag
            educationHubEnabled: educationHubEnabled // Pass the educationHubEnabled flag
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
        uint256 nextIndex = 7;
        if (electionEnabled) {
            params.contractNames[nextIndex++] = "ElectionContract";
        }

        // Add EducationHub if educationHubEnabled is true
        if (educationHubEnabled) {
            params.contractNames[nextIndex] = "EducationHub";
        }

        // Deploy the organization and return the registry address
        address registryAddress = masterFactory.deployAll(params);
        return registryAddress;
    }
}
