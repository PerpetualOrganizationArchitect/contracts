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

    function setUp() public {
        DeployMasterFactory deployMasterFactory = new DeployMasterFactory();
        address masterFactoryAddress = deployMasterFactory.run();
        masterFactory = MasterFactory(masterFactoryAddress);
    }

    function getRegistryCreatedAddress(Vm.Log[] memory logs, bytes32 eventSignature) internal pure returns (address) {
        for (uint256 i = 0; i < logs.length; i++) {
            console.log("Log index: ", i);
            console.logBytes32(logs[i].topics[0]);
            if (logs[i].topics[0] == eventSignature) {
                console.log("RegistryCreated event found");
                return address(uint160(uint256(logs[i].topics[0])));
            }
        }
        revert("RegistryCreated event not found in logs");
    }

    function testDeployDirectDemocracy() public {
        DeployDirectDemocracyOrg deployDirectDemocracyOrg = new DeployDirectDemocracyOrg();

        vm.recordLogs();
        deployDirectDemocracyOrg.run(address(masterFactory));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Ensure there are logs to process
        assertTrue(logs.length > 0, "No logs found after deployment");

        // Check if the deployment log length matches the expected number of logs
        assertEq(logs.length, 20, "Unexpected number of logs for Direct Democracy deployment");
        assertEq(
            logs[0].topics[0],
            keccak256("DeployParamsLog(string[],string[],string,bool,uint256,uint256,bool,bool,string,string,string[])")
        );
    }

    function testDeployParticipationVoting() public {
        DeployParticipationOrg deployParticipationOrg = new DeployParticipationOrg();

        vm.recordLogs();
        deployParticipationOrg.run(address(masterFactory));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Ensure there are logs to process
        assertTrue(logs.length > 0, "No logs found after deployment");

        // Check if the deployment log length matches the expected number of logs
        assertEq(logs.length, 21, "Unexpected number of logs for Participation Voting deployment");
        assertEq(
            logs[0].topics[0],
            keccak256("DeployParamsLog(string[],string[],string,bool,uint256,uint256,bool,bool,string,string,string[])")
        );
    }

    function testDeployHybridVoting() public {
        DeployHybridOrg deployHybridOrg = new DeployHybridOrg();

        vm.recordLogs();
        deployHybridOrg.run(address(masterFactory));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Ensure there are logs to process
        assertTrue(logs.length > 0, "No logs found after deployment");

        // Check if the deployment log length matches the expected number of logs
        assertEq(logs.length, 21, "Unexpected number of logs for Hybrid Voting deployment");
        assertEq(
            logs[0].topics[0],
            keccak256("DeployParamsLog(string[],string[],string,bool,uint256,uint256,bool,bool,string,string,string[])")
        );
    }
}
