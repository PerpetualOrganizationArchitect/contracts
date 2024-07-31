// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Registry.sol";

contract RegistryTest is Test {
    Registry public registry;
    address public votingControl = address(1);
    address public nonAuthorized = address(2);
    string[] public contractNames = ["ContractA", "ContractB"];
    address[] public contractAddresses = [address(3), address(4)];
    string public initialPOname = "OrgName";
    string public initialLogoURL = "http://logo.url";
    string public initialInfoHash = "infoHash123";

    function setUp() public {
        registry = new Registry(
            votingControl, contractNames, contractAddresses, initialPOname, initialLogoURL, initialInfoHash
        );
    }

    function testInitialization() public {
        assertEq(registry.VotingControlAddress(), votingControl);
        assertEq(registry.getContractAddress("ContractA"), address(3));
        assertEq(registry.getContractAddress("ContractB"), address(4));
        assertEq(registry.POname(), initialPOname);
        assertEq(registry.logoURL(), initialLogoURL);
        assertEq(registry.infoHash(), initialInfoHash);
    }

    function testSetVotingControlAddress() public {
        vm.prank(votingControl);
        address newVotingControl = address(5);
        registry.setVotingControlAddress(newVotingControl);
        assertEq(registry.VotingControlAddress(), newVotingControl);
    }

    function testSetVotingControlAddressUnauthorized() public {
        vm.prank(nonAuthorized);
        vm.expectRevert("Not authorized");
        registry.setVotingControlAddress(nonAuthorized);
    }

    function testAddContract() public {
        string memory newContractName = "ContractC";
        address newContractAddress = address(6);
        vm.prank(votingControl);
        registry.addContract(newContractName, newContractAddress);
        assertEq(registry.getContractAddress(newContractName), newContractAddress);
    }

    function testAddContractUnauthorized() public {
        vm.prank(nonAuthorized);
        vm.expectRevert("Not authorized");
        registry.addContract("ContractC", address(6));
    }

    function testUpgradeContract() public {
        string memory contractName = "ContractA";
        address newContractAddress = address(7);
        vm.prank(votingControl);
        registry.upgradeContract(contractName, newContractAddress);
        assertEq(registry.getContractAddress(contractName), newContractAddress);
    }

    function testUpgradeContractUnauthorized() public {
        vm.prank(nonAuthorized);
        vm.expectRevert("Not authorized");
        registry.upgradeContract("ContractA", address(7));
    }
}
