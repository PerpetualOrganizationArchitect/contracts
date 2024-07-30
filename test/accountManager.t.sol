// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/UniversalAccountRegistry.sol";

contract AccountManagerTest is Test {
    AccountManager public accountManager;

    address public user1 = address(1);
    address public user2 = address(2);
    address public user3 = address(3);
    address public quickJoinAddress = address(4);

    function setUp() public {
        accountManager = new AccountManager();
    }

    function testRegisterAccount() public {
        vm.prank(user1);
        accountManager.registerAccount("user1");

        string memory username = accountManager.getUsername(user1);
        assertEq(username, "user1");
    }

    function testRegisterAccountQuickJoin() public {
        vm.prank(quickJoinAddress);
        accountManager.registerAccountQuickJoin("user1", user1);

        string memory username = accountManager.getUsername(user1);
        assertEq(username, "user1");
    }

    function testCannotRegisterWithEmptyUsername() public {
        vm.prank(user1);
        vm.expectRevert("Username cannot be empty");
        accountManager.registerAccount("");
    }

    function testCannotRegisterSameUserTwice() public {
        vm.prank(user1);
        accountManager.registerAccount("user1");

        vm.prank(user1);
        vm.expectRevert("Account already registered");
        accountManager.registerAccount("user1_new");
    }

    function testCannotRegisterWithExistingUsername() public {
        vm.prank(user1);
        accountManager.registerAccount("user1");

        vm.prank(user2);
        vm.expectRevert("Username already taken");
        accountManager.registerAccount("user1");
    }

    function testChangeUsername() public {
        vm.prank(user1);
        accountManager.registerAccount("user1");

        vm.prank(user1);
        accountManager.changeUsername("newUser1");

        string memory username = accountManager.getUsername(user1);
        assertEq(username, "newUser1");
    }

    function testCannotChangeToEmptyUsername() public {
        vm.prank(user1);
        accountManager.registerAccount("user1");

        vm.prank(user1);
        vm.expectRevert("New username cannot be empty");
        accountManager.changeUsername("");
    }

    function testCannotChangeToExistingUsername() public {
        vm.prank(user1);
        accountManager.registerAccount("user1");

        vm.prank(user2);
        accountManager.registerAccount("user2");

        vm.prank(user1);
        vm.expectRevert("Username already taken");
        accountManager.changeUsername("user2");
    }

    function testGetUsername() public {
        vm.prank(user1);
        accountManager.registerAccount("user1");

        string memory username = accountManager.getUsername(user1);
        assertEq(username, "user1");

        string memory emptyUsername = accountManager.getUsername(user2);
        assertEq(emptyUsername, "");
    }

    function testCannotChangeUsernameIfNotRegistered() public {
        vm.prank(user1);
        vm.expectRevert("Account not registered");
        accountManager.changeUsername("newUser1");
    }

    function testCannotRegisterQuickJoinWithEmptyUsername() public {
        vm.prank(quickJoinAddress);
        vm.expectRevert("Username cannot be empty");
        accountManager.registerAccountQuickJoin("", user1);
    }

    function testCannotRegisterQuickJoinIfAlreadyRegistered() public {
        vm.prank(quickJoinAddress);
        accountManager.registerAccountQuickJoin("user1", user1);

        vm.prank(quickJoinAddress);
        vm.expectRevert("Account already registered");
        accountManager.registerAccountQuickJoin("user1_new", user1);
    }

    function testCannotRegisterQuickJoinWithExistingUsername() public {
        vm.prank(quickJoinAddress);
        accountManager.registerAccountQuickJoin("user1", user1);

        vm.prank(quickJoinAddress);
        vm.expectRevert("Username already taken");
        accountManager.registerAccountQuickJoin("user1", user2);
    }
}
