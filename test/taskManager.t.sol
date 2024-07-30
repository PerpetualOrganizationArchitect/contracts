// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TaskManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TaskManagerTest is Test {
    TaskManager public taskManager;
    IParticipationToken public participationToken;
    INFTMembership4 public nftMembership;

    address public owner = address(1);
    address public member1 = address(2);
    address public member2 = address(3);
    address public nonMember = address(4);

    string[] public allowedRoleNames = ["member"];

    function setUp() public {
        participationToken = new ParticipationTokenMock();
        nftMembership = new NFTMembershipMock();

        taskManager = new TaskManager(address(participationToken), address(nftMembership), allowedRoleNames);

        NFTMembershipMock(address(nftMembership)).setMemberType(owner, "member");
        NFTMembershipMock(address(nftMembership)).setMemberType(member1, "member");
        NFTMembershipMock(address(nftMembership)).setMemberType(member2, "member");
    }

    function testCreateTask() public {
        vm.prank(owner);
        taskManager.createTask(100, "ipfsHash1", "project1");

        (uint256 id, uint256 payout, bool isCompleted, address claimer) = taskManager.tasks(0);
        assertEq(id, 0);
        assertEq(payout, 100);
        assertEq(isCompleted, false);
        assertEq(claimer, address(0));
    }

    function testUpdateTask() public {
        vm.prank(owner);
        taskManager.createTask(100, "ipfsHash1", "project1");

        vm.prank(owner);
        taskManager.updateTask(0, 200, "ipfsHash2");

        (, uint256 payout,,) = taskManager.tasks(0);
        assertEq(payout, 200);
    }

    function testClaimTask() public {
        vm.prank(owner);
        taskManager.createTask(100, "ipfsHash1", "project1");

        vm.prank(member1);
        taskManager.claimTask(0);

        (,,, address claimer) = taskManager.tasks(0);
        assertEq(claimer, member1);
    }

    function testSubmitTask() public {
        vm.prank(owner);
        taskManager.createTask(100, "ipfsHash1", "project1");

        vm.prank(member1);
        taskManager.claimTask(0);

        vm.prank(member1);
        taskManager.submitTask(0, "ipfsHash2");
    }

    function testCompleteTask() public {
        vm.prank(owner);
        taskManager.createTask(100, "ipfsHash1", "project1");

        vm.prank(member1);
        taskManager.claimTask(0);

        vm.prank(member1);
        taskManager.submitTask(0, "ipfsHash2");

        vm.prank(owner);
        taskManager.completeTask(0);

        (,, bool isCompleted,) = taskManager.tasks(0);
        assertEq(isCompleted, true);

        assertEq(participationToken.balanceOf(member1), 100);
    }

    function testCreateProject() public {
        vm.prank(owner);
        taskManager.createProject("project1");
    }

    function testDeleteProject() public {
        vm.prank(owner);
        taskManager.createProject("project1");

        vm.prank(owner);
        taskManager.deleteProject("project1");
    }

    function testNonMemberCannotClaimTask() public {
        vm.prank(owner);
        taskManager.createTask(100, "ipfsHash1", "project1");

        vm.prank(nonMember);
        vm.expectRevert("Not a member");
        taskManager.claimTask(0);
    }

    function testNonMemberCannotSubmitTask() public {
        vm.prank(owner);
        taskManager.createTask(100, "ipfsHash1", "project1");

        vm.prank(member1);
        taskManager.claimTask(0);

        vm.prank(nonMember);
        vm.expectRevert("Not a member");
        taskManager.submitTask(0, "ipfsHash2");
    }

    function testNonAuthorizedCannotCreateTask() public {
        vm.prank(nonMember);
        vm.expectRevert("Not authorized to create task");
        taskManager.createTask(100, "ipfsHash1", "project1");
    }

    function testNonAuthorizedCannotUpdateTask() public {
        vm.prank(owner);
        taskManager.createTask(100, "ipfsHash1", "project1");

        vm.prank(nonMember);
        vm.expectRevert("Not authorized to create task");
        taskManager.updateTask(0, 200, "ipfsHash2");
    }

    function testNonAuthorizedCannotCompleteTask() public {
        vm.prank(owner);
        taskManager.createTask(100, "ipfsHash1", "project1");

        vm.prank(member1);
        taskManager.claimTask(0);

        vm.prank(member1);
        taskManager.submitTask(0, "ipfsHash2");

        vm.prank(nonMember);
        vm.expectRevert("Not authorized to create task");
        taskManager.completeTask(0);
    }

    function testNonAuthorizedCannotCreateProject() public {
        vm.prank(nonMember);
        vm.expectRevert("Not authorized to create task");
        taskManager.createProject("project1");
    }

    function testNonAuthorizedCannotDeleteProject() public {
        vm.prank(owner);
        taskManager.createProject("project1");

        vm.prank(nonMember);
        vm.expectRevert("Not authorized to create task");
        taskManager.deleteProject("project1");
    }
}

// Mock Contracts
contract ParticipationTokenMock is ERC20, IParticipationToken {
    address public taskManagerAddress;

    constructor() ERC20("Participation Token", "PT") {}

    function mint(address to, uint256 amount) external override {
        _mint(to, amount);
    }

    function setTaskManagerAddress(address _taskManagerAddress) external override {
        taskManagerAddress = _taskManagerAddress;
    }
}

contract NFTMembershipMock is INFTMembership4 {
    mapping(address => string) public memberTypeOf;
    address public quickJoin;

    function checkMemberTypeByAddress(address user) external view override returns (string memory) {
        return memberTypeOf[user];
    }

    function setMemberType(address user, string memory memberType) external {
        memberTypeOf[user] = memberType;
    }

    function setQuickJoin(address _quickJoin) external override {
        quickJoin = _quickJoin;
    }

    function mintDefaultNFT(address newUser) external override {
        memberTypeOf[newUser] = "Default";
    }
}
