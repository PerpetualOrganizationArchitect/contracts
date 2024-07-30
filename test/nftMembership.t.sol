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

    string[] public memberTypeNames = ["Default", "Gold", "Silver", "Executive"];
    string[] public executiveRoleNames = ["Executive"];
    string public defaultImageURL = "http://default-image.com";

    function setUp() public {
        nftMembership = new NFTMembership(memberTypeNames, executiveRoleNames, defaultImageURL);
        nftMembership.setQuickJoin(quickJoin);

        vm.prank(quickJoin);
        nftMembership.mintDefaultNFT(executive);
    }

    function testDefaultMintExecutive() public {
        assertEq(nftMembership.balanceOf(executive), 1);
        assertEq(nftMembership.checkMemberTypeByAddress(executive), "Executive");
        assertEq(nftMembership.tokenURI(0), defaultImageURL);
    }

    function testSetQuickJoin() public {
        assertEq(nftMembership.getQuickJoin(), quickJoin);
    }

    function testMintDefaultNFT() public {
        vm.prank(quickJoin);

        address user2 = address(5);
        nftMembership.mintDefaultNFT(user2);

        assertEq(nftMembership.balanceOf(user2), 1);
        assertEq(nftMembership.checkMemberTypeByAddress(user2), "Default");
        assertEq(nftMembership.tokenURI(1), defaultImageURL);
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

    function testFailMintNFT_NotExecutive() public {
        vm.prank(user);
        nftMembership.mintNFT(user, "Gold");
    }

    function testFailChangeMembershipType_NotExecutive() public {
        vm.prank(executive);
        nftMembership.mintNFT(user, "Gold");

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
