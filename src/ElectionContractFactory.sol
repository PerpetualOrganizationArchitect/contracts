// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ElectionContract.sol";

contract ElectionContractFactory {
    event ElectionContractCreated(
        address indexed electionContractAddress,
        address indexed nftMembershipAddress,
        address votingContractAddress,
        string POname
    );

    function createElectionContract(address _nftMembership, address _votingContractAddress, string memory POname)
        public
        returns (address)
    {
        ElectionContract newElectionContract = new ElectionContract(_nftMembership, _votingContractAddress);
        emit ElectionContractCreated(address(newElectionContract), _nftMembership, _votingContractAddress, POname);
        return address(newElectionContract);
    }
}
