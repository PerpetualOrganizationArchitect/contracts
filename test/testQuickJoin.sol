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
    address directDemocracyRegistryAddress;
    address accountManagerAddress;

    function setUp() public {
        DeployMasterFactory deployMasterFactory = new DeployMasterFactory();
        address masterFactoryAddress = deployMasterFactory.run();
        masterFactory = MasterFactory(masterFactoryAddress);

        // Retrieve the AccountManager address from the DeployMasterFactory
        accountManagerAddress = deployMasterFactory.accountManagerAddress();
    }

    function testQuickJoinNoUser() public {
        // Deploy the Direct Democracy organization
        DeployDirectDemocracyOrg deployDirectDemocracyOrg = new DeployDirectDemocracyOrg();
        directDemocracyRegistryAddress = deployDirectDemocracyOrg.run(address(masterFactory), false, false);

        // Get the registry instance
        Registry registry = Registry(directDemocracyRegistryAddress);

        // Retrieve contract addresses from the registry
        address nftMembershipAddress = registry.getContractAddress("NFTMembership");
        address directDemocracyTokenAddress = registry.getContractAddress("DirectDemocracyToken");
        address quickJoinAddress = registry.getContractAddress("QuickJoin");

        // Create interface instances for the contracts
        IERC721 membershipNFT = IERC721(nftMembershipAddress);
        IERC20 directDemocracyToken = IERC20(directDemocracyTokenAddress);
        QuickJoin quickJoin = QuickJoin(quickJoinAddress);
        IAccountManager accountManager = IAccountManager(accountManagerAddress);

        // Simulate a new user using vm.addr
        address newUser = vm.addr(1);

        // Simulate the new user calling quickJoinNoUser
        vm.prank(newUser);
        quickJoin.quickJoinNoUser("test");

        // Check that the new user has received the membership NFT
        uint256 nftBalance = membershipNFT.balanceOf(newUser);
        assertEq(nftBalance, 1, "User should have 1 NFT");

        // Check that the new user has received the Direct Democracy Token
        uint256 tokenBalance = directDemocracyToken.balanceOf(newUser);
        assertEq(tokenBalance, 100, "User should have 1 DirectDemocracyToken");

        // Check that the user is registered in the AccountManager
        string memory username = accountManager.getUsername(newUser);
        assertEq(
            keccak256(abi.encodePacked(username)), keccak256(abi.encodePacked("test")), "Username should be 'test'"
        );
    }
}
