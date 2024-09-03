// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/educationHub.sol";

contract MockParticipationToken2 is IParticipationToken2 {
    mapping(address => uint256) public balances;

    function mint(address to, uint256 amount) external override {
        balances[to] += amount;
    }

    function totalSupply() external view override returns (uint256) {
        return 0;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return false;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return 0;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        return false;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        return false;
    }
}

contract MockNFTMembership11 is INFTMembership11 {
    mapping(address => string) public memberTypes;
    mapping(address => bool) public executives;

    function checkMemberTypeByAddress(address user) external view override returns (string memory) {
        return memberTypes[user];
    }

    function checkIsExecutive(address user) external view override returns (bool) {
        return executives[user];
    }

    function setMemberType(address user, string memory memberType) external {
        memberTypes[user] = memberType;
    }

    function setExecutive(address user, bool isExec) external {
        executives[user] = isExec;
    }
}

contract EducationHubTest is Test {
    EducationHub public educationHub;
    MockParticipationToken2 public token;
    MockNFTMembership11 public nftMembership;

    address public owner = address(1);
    address public executive = address(2);
    address public member = address(3);
    address public nonMember = address(4);

    function setUp() public {
        token = new MockParticipationToken2();
        nftMembership = new MockNFTMembership11();

        // Set up roles
        nftMembership.setMemberType(member, "Member");
        nftMembership.setExecutive(executive, true);

        educationHub = new EducationHub(address(token), address(nftMembership));
    }

    function testCreateModule() public {
        vm.prank(executive);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);

        (uint256 id, string memory name, string memory ipfsHash, bool exists, uint256 payout, uint8 correctAnswer) =
            educationHub.modules(0);
        assertEq(id, 0);
        assertEq(name, "Intro to DAO");
        assertEq(ipfsHash, "ipfsHash1");
        assertTrue(exists);
        assertEq(payout, 100);
        assertEq(correctAnswer, 1);
    }

    function testFailCreateModule_NotExecutive() public {
        vm.prank(member);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);
    }

    function testCompleteModule() public {
        // Create a module as an executive
        vm.prank(executive);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);

        // Complete the module as a member
        vm.prank(member);
        educationHub.completeModule(0, 1);

        assertEq(token.balanceOf(member), 100);
        (bool completed) = educationHub.completedModules(member, 0);
        assertTrue(completed);
    }

    function testCompleteModule_IncorrectAnswer() public {
        // Create a module as an executive
        vm.prank(executive);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);

        // Attempt to complete the module with an incorrect answer
        vm.prank(member);
        vm.expectRevert("Incorrect answer");
        educationHub.completeModule(0, 2);
    }

    function testCompleteModule_NotAMember() public {
        // Create a module as an executive
        vm.prank(executive);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);

        // Attempt to complete the module as a non-member
        vm.prank(nonMember);
        vm.expectRevert("Not a member");
        educationHub.completeModule(0, 1);
    }

    function testCompleteModule_AlreadyCompleted() public {
        // Create a module as an executive
        vm.prank(executive);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);

        // Complete the module as a member
        vm.prank(member);
        educationHub.completeModule(0, 1);

        // Attempt to complete the module again
        vm.prank(member);
        vm.expectRevert("Module already completed");
        educationHub.completeModule(0, 1);
    }

    function testRemoveModule() public {
        // Create a module as an executive
        vm.prank(executive);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);

        // Remove the module as an executive
        vm.prank(executive);
        educationHub.removeModule(0);

        (,,, bool exists,,) = educationHub.modules(0);
        assertFalse(exists);
    }

    function testRemoveModule_NotExecutive() public {
        // Create a module as an executive
        vm.prank(executive);
        educationHub.createModule("Intro to DAO", "ipfsHash1", 100, 1);

        // Attempt to remove the module as a non-executive
        vm.prank(member);
        vm.expectRevert("Not an executive");
        educationHub.removeModule(0);
    }

    function testRemoveModule_NonExistentModule() public {
        // Attempt to remove a non-existent module
        vm.prank(executive);
        vm.expectRevert("Module does not exist");
        educationHub.removeModule(0);
    }

    function testCreateModule_InvalidPayout() public {
        // Attempt to create a module with zero payout
        vm.prank(executive);
        vm.expectRevert("Payout must be greater than zero");
        educationHub.createModule("Intro to DAO", "ipfsHash1", 0, 1);
    }
}
