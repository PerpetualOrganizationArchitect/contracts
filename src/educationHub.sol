// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IParticipationToken2 is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface INFTMembership11 {
    function checkMemberTypeByAddress(address user) external view returns (string memory);
    function checkIsExecutive(address user) external view returns (bool);
}

contract EducationHub {

    struct Module {
        uint256 id;
        string name;
        string ipfsHash;
        bool exists;
        uint256 payout;
        uint8 correctAnswer;
    }

    mapping(uint256 => Module) public modules;

    uint256 public _id;

    mapping(address => bool) public completedModules;

    IParticipationToken2 public token;
    INFTMembership11 public nftMembership;

    constructor(address _token, address _nftMembership) {
        token = IParticipationToken2(_token);
        nftMembership = INFTMembership11(_nftMembership);
    }

     modifier isMember() {
        string memory memberType = nftMembership.checkMemberTypeByAddress(msg.sender);
        require(bytes(memberType).length != 0, "Not a member");
        _;
    }

    modifier isExecutive() {
        require(nftMembership.checkIsExecutive(msg.sender), "Not an executive");
        _;
    }


    function createModule(string memory _name, string memory _ipfsHash, uint256 _payout, uint8 _correctAnswer) public isExecutive() {
        Module memory newModule;

        uint256 moduleId = _id++;

        newModule.id = moduleId;
        newModule.name = _name;
        newModule.ipfsHash = _ipfsHash;
        newModule.exists = true;
        newModule.payout = _payout;
        newModule.correctAnswer = _correctAnswer;

        modules[moduleId] = newModule;
    }

    function completeModule(uint256 _moduleId, uint8 _answer) public isMember() {
        Module memory module = modules[_moduleId];
        require(module.exists, "Module does not exist");
        require(_answer == module.correctAnswer, "Incorrect answer");

        if (!completedModules[msg.sender]) {
            token.mint(msg.sender, module.payout);
            completedModules[msg.sender] = true;
        }
    }
}