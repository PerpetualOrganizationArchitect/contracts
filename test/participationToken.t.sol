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

    function setUp() public {
        participationToken = new ParticipationToken("Participation Token", "PT");

        participationToken.setTaskManagerAddress(taskManager);
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
        vm.expectRevert("Only the task manager can call this function.");
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
}
