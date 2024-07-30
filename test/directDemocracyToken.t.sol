// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DirectDemocracyToken.sol";

contract DirectDemocracyTokenTest is Test {
    DirectDemocracyToken public directDemocracyToken;
    INFTMembership public nftMembership;

    address public owner = address(1);
    address public memberWithPermission = address(2);
    address public memberWithoutPermission = address(3);
    address public nonMember = address(4);
    address public quickJoin = address(5);

    string[] public allowedRoleNames = ["memberWithPermission"];

    function setUp() public {
        nftMembership = new NFTMembershipMock();
        directDemocracyToken = new DirectDemocracyToken("Direct Democracy Token", "DDT", address(nftMembership), allowedRoleNames);

        NFTMembershipMock(address(nftMembership)).setMemberType(owner, "memberWithPermission");
        NFTMembershipMock(address(nftMembership)).setMemberType(memberWithPermission, "memberWithPermission");
        NFTMembershipMock(address(nftMembership)).setMemberType(memberWithoutPermission, "memberWithoutPermission");

        directDemocracyToken.setQuickJoin(quickJoin);
    }

    function testMint() public {
        vm.prank(quickJoin);
        directDemocracyToken.mint(memberWithPermission);

        assertEq(directDemocracyToken.balanceOf(memberWithPermission), 100);
    }

    function testCannotMintTwice() public {
        vm.prank(quickJoin);
        directDemocracyToken.mint(memberWithPermission);

        vm.expectRevert("This account has already claimed coins!");
        vm.prank(quickJoin);
        directDemocracyToken.mint(memberWithPermission);
    }

    function testNonQuickJoinCannotMint() public {
        vm.expectRevert("Only QuickJoin can call this function");
        directDemocracyToken.mint(memberWithPermission);
    }

    function testMemberWithoutPermissionCannotMint() public {
        vm.expectRevert("Not authorized to mint coins");
        vm.prank(quickJoin);
        directDemocracyToken.mint(memberWithoutPermission);
    }

    function testNonMemberCannotMint() public {
        vm.expectRevert("Not authorized to mint coins");
        vm.prank(quickJoin);
        directDemocracyToken.mint(nonMember);
    }

    function testTransferNotAllowed() public {
        vm.prank(quickJoin);
        directDemocracyToken.mint(memberWithPermission);

        vm.expectRevert("Transfer of tokens is not allowed");
        directDemocracyToken.transfer(nonMember, 50);
    }

    function testApproveNotAllowed() public {
        vm.prank(quickJoin);
        directDemocracyToken.mint(memberWithPermission);

        vm.expectRevert("Approval of Token allowance is not allowed");
        directDemocracyToken.approve(nonMember, 50);
    }

    function testTransferFromNotAllowed() public {
        vm.prank(quickJoin);
        directDemocracyToken.mint(memberWithPermission);

        vm.expectRevert("Transfer of Tokens is not allowed");
        directDemocracyToken.transferFrom(memberWithPermission, nonMember, 50);
    }

    function testDecimals() public {
        assertEq(directDemocracyToken.decimals(), 0);
    }

    function testGetBalance() public {
        vm.prank(quickJoin);
        directDemocracyToken.mint(memberWithPermission);

        assertEq(directDemocracyToken.getBalance(memberWithPermission), 100);
    }
}

// Mock Contracts
contract NFTMembershipMock is INFTMembership {
    mapping(address => string) public memberTypeOf;

    function checkMemberTypeByAddress(address user) external view override returns (string memory) {
        return memberTypeOf[user];
    }

    function setMemberType(address user, string memory memberType) external {
        memberTypeOf[user] = memberType;
    }
}
