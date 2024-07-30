// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./QuickJoin.sol";

contract QuickJoinFactory {
    event QuickJoinDeployed(address quickJoinAddress, string POname);

    function createQuickJoin(
        address _membershipNFTAddress,
        address _directDemocracyTokenAddress,
        address _accountManagerAddress,
        string memory _POname,
        address _masterDeployAddress
    ) public returns (address) {
        QuickJoin quickJoin = new QuickJoin(
            _membershipNFTAddress, _directDemocracyTokenAddress, _accountManagerAddress, _masterDeployAddress
        );

        emit QuickJoinDeployed(address(quickJoin), _POname);
        return address(quickJoin);
    }
}
