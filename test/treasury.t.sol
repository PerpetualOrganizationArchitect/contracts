// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Treasury.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TreasuryTest is Test {
    Treasury public treasury;
    ERC20Mock public token;
    address public votingContract = address(1);
    address public user = address(2);
    address public nonVotingContract = address(3);

    function setUp() public {
        treasury = new Treasury();
        token = new ERC20Mock();

        token.mint(address(treasury), 1000);
    }

    function testSetVotingContract() public {
        treasury.setVotingContract(votingContract);
        assertEq(treasury.votingContract(), votingContract);
    }

    function testSetVotingContractFail() public {
        treasury.setVotingContract(votingContract);
        vm.expectRevert("Voting contract already set");
        treasury.setVotingContract(votingContract);
    }

    function testSendTokens() public {
        treasury.setVotingContract(votingContract);

        vm.prank(votingContract);
        treasury.sendTokens(address(token), user, 500);

        assertEq(token.balanceOf(user), 500);
        assertEq(token.balanceOf(address(treasury)), 500);
    }

    function testSendTokensFailNotVotingContract() public {
        treasury.setVotingContract(votingContract);

        vm.prank(nonVotingContract);
        vm.expectRevert("Caller is not the voting contract");
        treasury.sendTokens(address(token), user, 500);
    }

    function testSendTokensFailInsufficientBalance() public {
        treasury.setVotingContract(votingContract);

        vm.prank(votingContract);
        vm.expectRevert("Insufficient balance");
        treasury.sendTokens(address(token), user, 1500);
    }

    function testReceiveTokens() public {
        token.mint(user, 500);

        vm.prank(user);
        token.approve(address(treasury), 500);

        vm.prank(user);
        treasury.receiveTokens(address(token), user, 500);

        assertEq(token.balanceOf(user), 0);
        assertEq(token.balanceOf(address(treasury)), 1500);
    }

    function testWithdrawEther() public {
        treasury.setVotingContract(votingContract);

        address(treasury).call{value: 1 ether}("");
        assertEq(address(treasury).balance, 1 ether);

        vm.prank(votingContract);
        treasury.withdrawEther(payable(user), 0.5 ether);

        assertEq(address(treasury).balance, 0.5 ether);
        assertEq(address(user).balance, 0.5 ether);
    }

    function testWithdrawEtherFailNotVotingContract() public {
        treasury.setVotingContract(votingContract);

        address(treasury).call{value: 1 ether}("");
        assertEq(address(treasury).balance, 1 ether);

        vm.prank(nonVotingContract);
        vm.expectRevert("Caller is not the voting contract");
        treasury.withdrawEther(payable(user), 0.5 ether);
    }

    function testWithdrawEtherFailInsufficientBalance() public {
        treasury.setVotingContract(votingContract);

        address(treasury).call{value: 0.5 ether}("");
        assertEq(address(treasury).balance, 0.5 ether);

        vm.prank(votingContract);
        vm.expectRevert("Insufficient Ether balance");
        treasury.withdrawEther(payable(user), 1 ether);
    }

    function testReceiveEther() public {
        address(treasury).call{value: 1 ether}("");
        assertEq(address(treasury).balance, 1 ether);
    }
}

// Mock ERC20 contract
contract ERC20Mock is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
