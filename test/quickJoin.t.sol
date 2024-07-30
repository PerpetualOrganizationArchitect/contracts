// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/QuickJoin.sol";

contract QuickJoinTest is Test {
    QuickJoin public quickJoin;
    IMembershipNFT public membershipNFT;
    IDirectDemocracyToken public directDemocracyToken;
    IAccountManager public accountManager;

    address public masterDeployAddress = address(10);
    address public user1 = address(1);
    address public user2 = address(2);
    address public newUser = address(3);

    function setUp() public {
        membershipNFT = new MembershipNFTMock();
        directDemocracyToken = new DirectDemocracyTokenMock();
        accountManager = new AccountManagerMock();

        quickJoin = new QuickJoin(
            address(membershipNFT), address(directDemocracyToken), address(accountManager), masterDeployAddress
        );

        AccountManagerMock(address(accountManager)).setUser(user1, "existingUser");
    }

    function testQuickJoinNoUser() public {
        vm.prank(user2);
        quickJoin.quickJoinNoUser("newUser");

        string memory username = accountManager.getUsername(user2);
        assertEq(username, "newUser");
        assertTrue(MembershipNFTMock(address(membershipNFT)).hasNFT(user2));
        assertTrue(DirectDemocracyTokenMock(address(directDemocracyToken)).hasMinted(user2));
    }

    function testQuickJoinNoUserWithExistingUsername() public {
        vm.prank(user1);
        quickJoin.quickJoinNoUser("newUser");

        string memory username = accountManager.getUsername(user1);
        assertEq(username, "existingUser");
        assertTrue(MembershipNFTMock(address(membershipNFT)).hasNFT(user1));
        assertTrue(DirectDemocracyTokenMock(address(directDemocracyToken)).hasMinted(user1));
    }

    function testQuickJoinWithUser() public {
        vm.prank(user2);
        quickJoin.quickJoinWithUser();

        assertTrue(MembershipNFTMock(address(membershipNFT)).hasNFT(user2));
        assertTrue(DirectDemocracyTokenMock(address(directDemocracyToken)).hasMinted(user2));
    }

    function testQuickJoinNoUserMasterDeploy() public {
        vm.prank(masterDeployAddress);
        quickJoin.quickJoinNoUserMasterDeploy("newUserMD", newUser);

        string memory username = accountManager.getUsername(newUser);
        assertEq(username, "newUserMD");
        assertTrue(MembershipNFTMock(address(membershipNFT)).hasNFT(newUser));
        assertTrue(DirectDemocracyTokenMock(address(directDemocracyToken)).hasMinted(newUser));
    }

    function testQuickJoinNoUserMasterDeployWithExistingUsername() public {
        vm.prank(masterDeployAddress);
        quickJoin.quickJoinNoUserMasterDeploy("existingUserMD", user1);

        string memory username = accountManager.getUsername(user1);
        assertEq(username, "existingUser");
        assertTrue(MembershipNFTMock(address(membershipNFT)).hasNFT(user1));
        assertTrue(DirectDemocracyTokenMock(address(directDemocracyToken)).hasMinted(user1));
    }

    function testQuickJoinWithUserMasterDeploy() public {
        vm.prank(masterDeployAddress);
        quickJoin.quickJoinWithUserMasterDeploy(newUser);

        assertTrue(MembershipNFTMock(address(membershipNFT)).hasNFT(newUser));
        assertTrue(DirectDemocracyTokenMock(address(directDemocracyToken)).hasMinted(newUser));
    }

    function testNonMasterDeployCannotCallQuickJoinNoUserMasterDeploy() public {
        vm.prank(user1);
        vm.expectRevert("Only MasterDeploy can call this function");
        quickJoin.quickJoinNoUserMasterDeploy("nonMasterDeployUser", newUser);
    }

    function testNonMasterDeployCannotCallQuickJoinWithUserMasterDeploy() public {
        vm.prank(user1);
        vm.expectRevert("Only MasterDeploy can call this function");
        quickJoin.quickJoinWithUserMasterDeploy(newUser);
    }
}

// Mock Contracts
contract MembershipNFTMock is IMembershipNFT {
    mapping(address => bool) private hasMintedNFT;

    function mintDefaultNFT(address newUser) external override {
        hasMintedNFT[newUser] = true;
    }

    function hasNFT(address user) external view returns (bool) {
        return hasMintedNFT[user];
    }
}

contract DirectDemocracyTokenMock is IDirectDemocracyToken {
    mapping(address => bool) private hasMintedToken;

    function mint(address newUser) external override {
        hasMintedToken[newUser] = true;
    }

    function hasMinted(address user) external view returns (bool) {
        return hasMintedToken[user];
    }
}

contract AccountManagerMock is IAccountManager {
    mapping(address => string) private userNames;

    function getUsername(address accountAddress) external view override returns (string memory) {
        return userNames[accountAddress];
    }

    function registerAccount(string memory username) external override {
        userNames[msg.sender] = username;
    }

    function registerAccountQuickJoin(string memory username, address newUser) external override {
        userNames[newUser] = username;
    }

    function setUser(address user, string memory username) external {
        userNames[user] = username;
    }
}
