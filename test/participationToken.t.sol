// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ParticipationToken.sol";

contract ParticipationTokenTest is Test {
    ParticipationToken public participationToken;
    address public owner = address(1);
    address public taskManager = address(2);
    address public user = address(3);
    address public otherUser = address(4);
    address public nftMembership = address(5);
    address public executive = address(6);

    function setUp() public {
        participationToken = new ParticipationToken("Participation Token", "PT", nftMembership);

        participationToken.setTaskManagerAddress(taskManager);

        // Mocking the INFTMembership9 contract to return specific roles for addresses
        vm.mockCall(
            nftMembership,
            abi.encodeWithSelector(INFTMembership9.checkMemberTypeByAddress.selector, user),
            abi.encode("Member")
        );
        vm.mockCall(
            nftMembership,
            abi.encodeWithSelector(INFTMembership9.checkMemberTypeByAddress.selector, executive),
            abi.encode("Executive")
        );
        vm.mockCall(
            nftMembership,
            abi.encodeWithSelector(INFTMembership9.checkMemberTypeByAddress.selector, otherUser),
            abi.encode("")
        );
    }

    function testSetTaskManagerAddress() public {
        assertEq(participationToken.getTaskManagerAddress(), taskManager);
    }

    function testSetTaskManagerAddressFail() public {
        vm.prank(taskManager);
        vm.expectRevert("Task manager address already set.");
        participationToken.setTaskManagerAddress(taskManager);
    }

    function testMint() public {
        vm.prank(taskManager);
        participationToken.mint(user, 1000);

        assertEq(participationToken.balanceOf(user), 1000);
    }

    function testMintFailNotTaskManager() public {
        vm.prank(owner);
        vm.expectRevert("Only the task manager or education hub can call this function.");
        participationToken.mint(user, 1000);
    }

    function testTransferDisabled() public {
        vm.prank(taskManager);
        participationToken.mint(user, 1000);

        vm.prank(user);
        vm.expectRevert("Transfers are disabled.");
        participationToken.transfer(otherUser, 500);
    }

    function testTransferFromDisabled() public {
        vm.prank(taskManager);
        participationToken.mint(user, 1000);

        vm.prank(user);
        participationToken.approve(otherUser, 500);

        vm.prank(otherUser);
        vm.expectRevert("Transfers are disabled.");
        participationToken.transferFrom(user, otherUser, 500);
    }

    function testRequestTokens() public {
        vm.prank(user);
        participationToken.requestTokens(100, "ipfsHash");

        (address requester, uint256 amount, string memory ipfsHash, bool approved, bool exists) =
            participationToken.tokenRequests(1);

        assertEq(requester, user);
        assertEq(amount, 100);
        assertEq(ipfsHash, "ipfsHash");
        assertEq(approved, false);
        assertEq(exists, true);
    }

    function testRequestTokensFailNonMember() public {
        vm.prank(otherUser);
        vm.expectRevert("Caller is not a member.");
        participationToken.requestTokens(100, "ipfsHash");
    }

    function testApproveRequest() public {
        vm.prank(user);
        participationToken.requestTokens(100, "ipfsHash");

        vm.prank(executive);
        participationToken.approveRequest(1);

        (address requester, uint256 amount,, bool approved,) = participationToken.tokenRequests(1);

        assertEq(approved, true);
        assertEq(participationToken.balanceOf(user), amount);
    }

    function testApproveRequestFailNonExecutive() public {
        vm.prank(user);
        participationToken.requestTokens(100, "ipfsHash");

        vm.prank(user);
        vm.expectRevert("Caller is not an executive.");
        participationToken.approveRequest(1);
    }

    function testApproveRequestFailRequester() public {
        vm.prank(executive);
        participationToken.requestTokens(100, "ipfsHash");

        vm.prank(executive);
        vm.expectRevert("Requester cannot approve their own request.");
        participationToken.approveRequest(1);
    }

    function testApproveRequestFailNonExistentRequest() public {
        vm.prank(executive);
        vm.expectRevert("Request does not exist.");
        participationToken.approveRequest(1);
    }

    function testApproveRequestFailAlreadyApproved() public {
        vm.prank(user);
        participationToken.requestTokens(100, "ipfsHash");

        vm.prank(executive);
        participationToken.approveRequest(1);

        vm.prank(executive);
        vm.expectRevert("Request already approved.");
        participationToken.approveRequest(1);
    }
}
