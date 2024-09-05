// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./educationHub.sol";

contract EducationHubFactory {
    event EducationHubCreated(address indexed educationHubAddress, string POname);

    function createEducationHub(address token, address nftMembershipAddress, string memory POname)
        public
        returns (address)
    {
        EducationHub newEducationHub = new EducationHub(token, nftMembershipAddress);
        emit EducationHubCreated(address(newEducationHub), POname);
        return address(newEducationHub);
    }
}
