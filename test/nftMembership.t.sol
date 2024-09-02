// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MembershipNFT.sol";

contract NFTMembershipTest is Test {
    NFTMembership public nftMembership;

    address public owner = address(1);
    address public executive = address(2);
    address public user = address(3);
    address public quickJoin = address(4);
    address public anotherExecutive = address(5);
    address public thirdExecutive = address(6);

    string[] public memberTypeNames = ["Default", "Gold", "Silver", "Executive"];
    string[] public executiveRoleNames = ["Executive"];
    string public defaultImageURL = "http://default-image.com";

    function setUp() public {
        nftMembership = new NFTMembership(memberTypeNames, executiveRoleNames, defaultImageURL);
        nftMembership.setQuickJoin(quickJoin);

        vm.prank(quickJoin);
        nftMembership.mintDefaultNFT(executive);

        vm.prank(executive);
        nftMembership.mintNFT(anotherExecutive, "Executive");

        vm.prank(executive);
        nftMembership.mintNFT(thirdExecutive, "Executive");
    }

    function testDefaultMintExecutive() public {
        assertEq(nftMembership.balanceOf(executive), 1);
        assertEq(nftMembership.checkMemberTypeByAddress(executive), "Executive");
        assertEq(nftMembership.tokenURI(0), defaultImageURL);

        assertEq(nftMembership.balanceOf(anotherExecutive), 1);
        assertEq(nftMembership.checkMemberTypeByAddress(anotherExecutive), "Executive");
    }

    function testSetQuickJoin() public {
        assertEq(nftMembership.getQuickJoin(), quickJoin);
    }

    function testMintDefaultNFT() public {
        vm.prank(quickJoin);

        address user2 = address(7);
        nftMembership.mintDefaultNFT(user2);

        assertEq(nftMembership.balanceOf(user2), 1);
        assertEq(nftMembership.checkMemberTypeByAddress(user2), "Default");
        assertEq(nftMembership.tokenURI(2), defaultImageURL);
    }

    function testMintNFT() public {
        vm.prank(executive);
        nftMembership.mintNFT(user, "Gold");

        assertEq(nftMembership.balanceOf(user), 1);
        assertEq(nftMembership.checkMemberTypeByAddress(user), "Gold");
        assertEq(nftMembership.tokenURI(0), defaultImageURL);
    }

    function testChangeMembershipType() public {
        vm.prank(executive);
        nftMembership.mintNFT(user, "Gold");

        vm.prank(executive);
        nftMembership.changeMembershipType(user, "Silver");

        assertEq(nftMembership.checkMemberTypeByAddress(user), "Silver");
    }

    function testGiveUpExecutiveRole() public {
        vm.prank(executive);
        nftMembership.giveUpExecutiveRole();

        assertEq(nftMembership.checkMemberTypeByAddress(executive), "Default");
    }

    function testRemoveMember() public {
        vm.prank(executive);
        nftMembership.mintNFT(user, "Gold");

        vm.prank(executive);
        nftMembership.removeMember(user);

        vm.expectRevert("No member type found for user.");
        nftMembership.checkMemberTypeByAddress(user);
    }

    function testDowngradeExecutive() public {
        vm.warp(block.timestamp + 1 weeks);
        vm.prank(executive);
        nftMembership.downgradeExecutive(anotherExecutive);

        assertEq(nftMembership.checkMemberTypeByAddress(anotherExecutive), "Default");
    }

    function testDowngradeExecutive_SameWeek() public {
        vm.warp(block.timestamp + 1 weeks);
        vm.prank(executive);
        nftMembership.downgradeExecutive(anotherExecutive);

        vm.prank(executive);
        vm.expectRevert("Downgrade limit reached. Try again in a week.");
        nftMembership.downgradeExecutive(thirdExecutive);
    }

    function testDowngradeExecutive_AfterWeek() public {
        vm.warp(block.timestamp + 1 weeks);
        vm.prank(executive);
        nftMembership.downgradeExecutive(anotherExecutive);

        // Advance time by one week
        vm.warp(block.timestamp + 2 weeks);

        vm.prank(executive);
        nftMembership.downgradeExecutive(thirdExecutive);

        assertEq(nftMembership.checkMemberTypeByAddress(thirdExecutive), "Default");
    }

    function testFailMintNFT_NotExecutive() public {
        vm.prank(user);
        nftMembership.mintNFT(user, "Gold");
    }

    function testFailChangeMembershipType_NotExecutive() public {
        vm.prank(executive);
        nftMembership.mintNFT(user, "Gold");
        assertEq(nftMembership.checkMemberTypeByAddress(user), "Gold");

        vm.prank(user);
        nftMembership.changeMembershipType(user, "Silver");
    }

    function testFailMintNFT_InvalidMemberType() public {
        vm.prank(executive);
        nftMembership.mintNFT(user, "Platinum");
    }

    function testSetMemberTypeImage() public {
        vm.prank(owner);
        nftMembership.setMemberTypeImage("Gold", "http://gold-image.com");
        assertEq(nftMembership.memberTypeImages("Gold"), "http://gold-image.com");
    }

    function testFailSetQuickJoin_AfterAlreadySet() public {
        vm.prank(owner);
        nftMembership.setQuickJoin(quickJoin);

        address anotherQuickJoin = address(6);
        vm.prank(owner);
        nftMembership.setQuickJoin(anotherQuickJoin); // Should fail
    }

    function testFailMintDefaultNFT_NotQuickJoin() public {
        nftMembership.mintDefaultNFT(user); // Should fail
    }
}
