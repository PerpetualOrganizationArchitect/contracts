// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DirectDemocracyTokenFactory.sol";
import "./DirectDemocracyVotingFactory.sol";
import "./HybridVotingFactory.sol";
import "./ParticipationTokenFactory.sol";
import "./ParticipationVotingFactory.sol";
import "./TreasuryFactory.sol";
import "./MembershipNFTFactory.sol";
import "./RegistryFactory.sol";
import "./TaskManagerFactory.sol";
import "./QuickJoinFactory.sol";
import "./ElectionContractFactory.sol";

contract MasterFactory {
    event DeployParamsLog(
        string[] memberTypeNames,
        string[] executivePermissionNames,
        string POname,
        bool quadraticVotingEnabled,
        uint256 democracyVoteWeight,
        uint256 participationVoteWeight,
        bool hybridVotingEnabled,
        bool participationVotingEnabled,
        string logoURL,
        string votingControlType,
        string[] contractNames
    );

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
    ElectionContractFactory electionContractFactory;
    address accountManagerAddress;

    struct DeployParams {
        string[] memberTypeNames;
        string[] executivePermissionNames;
        string POname;
        bool quadraticVotingEnabled;
        uint256 democracyVoteWeight;
        uint256 participationVoteWeight;
        bool hybridVotingEnabled;
        bool participationVotingEnabled;
        string logoURL;
        string infoIPFSHash;
        string votingControlType;
        string[] contractNames;
        uint256 quorumPercentageDD;
        uint256 quorumPercentagePV;
        string username;
        bool electionEnabled;
    }

    constructor(
        address _directDemocracyTokenFactory,
        address _directDemocracyVotingFactory,
        address _hybridVotingFactory,
        address _participationTokenFactory,
        address _participationVotingFactory,
        address _treasuryFactory,
        address _nftMembershipFactory,
        address _registryFactory,
        address _taskManagerFactory,
        address _quickJoinFactory,
        address _accountManagerAddress,
        address _electionContractFactory
    ) {
        directDemocracyTokenFactory = DirectDemocracyTokenFactory(_directDemocracyTokenFactory);
        directDemocracyVotingFactory = DirectDemocracyVotingFactory(_directDemocracyVotingFactory);
        hybridVotingFactory = HybridVotingFactory(_hybridVotingFactory);
        participationTokenFactory = ParticipationTokenFactory(_participationTokenFactory);
        participationVotingFactory = ParticipationVotingFactory(_participationVotingFactory);
        treasuryFactory = TreasuryFactory(_treasuryFactory);
        nftMembershipFactory = NFTMembershipFactory(_nftMembershipFactory);
        registryFactory = RegistryFactory(_registryFactory);
        taskManagerFactory = TaskManagerFactory(_taskManagerFactory);
        quickJoinFactory = QuickJoinFactory(_quickJoinFactory);
        electionContractFactory = ElectionContractFactory(_electionContractFactory);
        accountManagerAddress = _accountManagerAddress;
    }

    function deployAll(DeployParams memory params) public returns (address) {
        emit DeployParamsLog(
            params.memberTypeNames,
            params.executivePermissionNames,
            params.POname,
            params.quadraticVotingEnabled,
            params.democracyVoteWeight,
            params.participationVoteWeight,
            params.hybridVotingEnabled,
            params.participationVotingEnabled,
            params.logoURL,
            params.votingControlType,
            params.contractNames
        );

        uint256 totalContracts = 7; // Standard contracts (NFTMembership, DDToken, ParticipationToken, Treasury, DD Voting, TaskManager, QuickJoin)
        if (params.hybridVotingEnabled || params.participationVotingEnabled) totalContracts++;
        if (params.electionEnabled) totalContracts++;

        address[] memory contractAddresses = new address[](totalContracts);
        uint256 contractIndex = 0;

        // Deploy standard contracts
        contractAddresses[contractIndex++] =
            deployNFTMembership(params.memberTypeNames, params.executivePermissionNames, params.logoURL, params.POname);
        contractAddresses[contractIndex++] =
            deployDirectDemocracyToken(contractAddresses[0], params.executivePermissionNames, params.POname);
        contractAddresses[contractIndex++] = deployParticipationToken(params.POname, contractAddresses[0]);
        contractAddresses[contractIndex++] = deployTreasury(params.POname);

        // Deploy conditional contracts
        contractAddresses[contractIndex++] = deployDemocracyVoting(
            contractAddresses, params.executivePermissionNames, params.POname, params.quorumPercentageDD
        );

        if (params.hybridVotingEnabled) {
            contractAddresses[contractIndex++] = deployHybridVoting(contractAddresses, params);
        } else if (params.participationVotingEnabled) {
            contractAddresses[contractIndex++] = deployPartcipationVoting(
                contractAddresses,
                params.executivePermissionNames,
                params.quadraticVotingEnabled,
                params.POname,
                params.quorumPercentagePV
            );
        }

        contractAddresses[contractIndex++] = taskManagerFactory.createTaskManager(
            contractAddresses[2], contractAddresses[0], params.executivePermissionNames, params.POname
        );

        INFTMembership7 nftMembership = INFTMembership7(contractAddresses[0]);

        if (params.electionEnabled) {
            contractAddresses[contractIndex++] = deployElectionContract(contractAddresses, params.POname);

            IDirectDemocracyVoting directDemocracyVoting = IDirectDemocracyVoting(contractAddresses[4]);
            directDemocracyVoting.setElectionsContract(contractAddresses[contractIndex - 1]);

            nftMembership.setElectionContract(contractAddresses[contractIndex - 1]);
        }

        // Ensure the contractAddresses array is properly indexed before calling setters
        address votingControlAddress = determineVotingControlAddress(params.votingControlType, contractAddresses);

        ITreasury treasury = ITreasury(contractAddresses[3]);
        treasury.setVotingContract(votingControlAddress);

        IParticipationToken token = IParticipationToken(contractAddresses[2]);
        token.setTaskManagerAddress(contractAddresses[contractIndex - 1]); // TaskManager should be the second to last deployed contract

        contractAddresses[contractIndex++] = quickJoinFactory.createQuickJoin(
            contractAddresses[0], contractAddresses[1], accountManagerAddress, params.POname, address(this)
        );

        IQuickJoin quickJoin = IQuickJoin(contractAddresses[contractIndex - 1]);

        IDirectDemocracyToken2 directDemocracyToken = IDirectDemocracyToken2(contractAddresses[1]);
        directDemocracyToken.setQuickJoin(contractAddresses[contractIndex - 1]);

        nftMembership.setQuickJoin(contractAddresses[contractIndex - 1]);

        if (bytes(params.username).length > 0) {
            quickJoin.quickJoinNoUserMasterDeploy(params.username, msg.sender);
        } else {
            quickJoin.quickJoinWithUserMasterDeploy(msg.sender);
        }

        // Create the registry and return its address
        address registryAddress = registryFactory.createRegistry(
            votingControlAddress,
            params.contractNames,
            contractAddresses,
            params.POname,
            params.logoURL,
            params.infoIPFSHash
        );

        return registryAddress;
    }

    function deployNFTMembership(
        string[] memory memberTypeNames,
        string[] memory executivePermissionNames,
        string memory logoURL,
        string memory POname
    ) internal returns (address) {
        return nftMembershipFactory.createNFTMembership(memberTypeNames, executivePermissionNames, logoURL, POname);
    }

    function deployDirectDemocracyToken(
        address nftAddress,
        string[] memory executivePermissionNames,
        string memory POname
    ) internal returns (address) {
        return directDemocracyTokenFactory.createDirectDemocracyToken(
            "DirectDemocracyToken", "DDT", nftAddress, executivePermissionNames, POname
        );
    }

    function deployParticipationToken(string memory POname, address nftAddress) internal returns (address) {
        return participationTokenFactory.createParticipationToken("ParticipationToken", "PT", POname, nftAddress);
    }

    function deployTreasury(string memory POname) internal returns (address) {
        return treasuryFactory.createTreasury(POname);
    }

    function deployElectionContract(address[] memory contractAddresses, string memory POname)
        internal
        returns (address)
    {
        return electionContractFactory.createElectionContract(
            contractAddresses[0], // NFT Membership Address
            contractAddresses[4], // Voting Contract Address (Direct Democracy Voting)
            POname
        );
    }

    function deployPartcipationVoting(
        address[] memory contractAddresses,
        string[] memory _allowedRoleNames,
        bool _quadraticVotingEnabled,
        string memory POname,
        uint256 quorumPercentagePV
    ) internal returns (address) {
        return participationVotingFactory.createParticipationVoting(
            contractAddresses[2],
            contractAddresses[0],
            _allowedRoleNames,
            _quadraticVotingEnabled,
            contractAddresses[3],
            POname,
            quorumPercentagePV
        );
    }

    function deployDemocracyVoting(
        address[] memory contractAddresses,
        string[] memory _allowedRoleNames,
        string memory POname,
        uint256 quorumPercentageDD
    ) internal returns (address) {
        return directDemocracyVotingFactory.createDirectDemocracyVoting(
            contractAddresses[1],
            contractAddresses[0],
            _allowedRoleNames,
            contractAddresses[3],
            POname,
            quorumPercentageDD
        );
    }

    function deployHybridVoting(address[] memory contractAddresses, DeployParams memory params)
        internal
        returns (address)
    {
        return hybridVotingFactory.createHybridVoting(
            contractAddresses[2],
            contractAddresses[1],
            contractAddresses[0],
            params.executivePermissionNames,
            params.quadraticVotingEnabled,
            params.democracyVoteWeight,
            params.participationVoteWeight,
            contractAddresses[3],
            params.POname,
            params.quorumPercentagePV
        );
    }

    function determineVotingControlAddress(string memory votingControlType, address[] memory contractAddresses)
        internal
        pure
        returns (address)
    {
        if (keccak256(abi.encodePacked(votingControlType)) == keccak256(abi.encodePacked("Hybrid"))) {
            return contractAddresses[5];
        } else if (keccak256(abi.encodePacked(votingControlType)) == keccak256(abi.encodePacked("DirectDemocracy"))) {
            return contractAddresses[4];
        } else if (keccak256(abi.encodePacked(votingControlType)) == keccak256(abi.encodePacked("Participation"))) {
            return contractAddresses[5];
        } else {
            revert("Invalid voting control type");
        }
    }
}

interface IQuickJoin {
    function quickJoinNoUserMasterDeploy(string memory userName, address newUser) external;
    function quickJoinWithUserMasterDeploy(address newUser) external;
}

interface IDirectDemocracyToken2 {
    function setQuickJoin(address _quickJoin) external;
}

interface IDirectDemocracyVoting {
    function setElectionsContract(address _electionContract) external;
}

interface INFTMembership7 {
    function setElectionContract(address _electionContract) external;
    function setQuickJoin(address _quickJoin) external;
}
