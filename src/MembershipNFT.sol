// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "forge-std/console.sol";

contract NFTMembership is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    mapping(uint256 => string) public memberTypeNames;
    mapping(string => string) public memberTypeImages;
    mapping(address => string) public memberTypeOf;
    mapping(uint256 => string) public executiveRoleNames;
    mapping(string => bool) public isExecutiveRole;
    mapping(address => uint256) public lastDowngradeTime;

    address quickJoin;
    bool quickJoinSet = false;

    address public electionContract;
    uint256 private constant ONE_WEEK = 1 weeks;

    string private constant DEFAULT_MEMBER_TYPE = "Default";
    string private defaultImageURL;

    event mintedNFT(address recipient, string memberTypeName, string tokenURI);
    event membershipTypeChanged(address user, string newMemberType);
    event MemberRemoved(address user);
    event ExecutiveDowngraded(address downgradedExecutive, address downgrader);

    constructor(string[] memory _memberTypeNames, string[] memory _executiveRoleNames, string memory _defaultImageURL)
        ERC721("MembershipNFT", "MNF")
    {
        defaultImageURL = _defaultImageURL;
        for (uint256 i = 0; i < _memberTypeNames.length; i++) {
            memberTypeNames[i] = _memberTypeNames[i];

            memberTypeImages[_memberTypeNames[i]] = _defaultImageURL;
        }

        for (uint256 i = 0; i < _executiveRoleNames.length; i++) {
            isExecutiveRole[_executiveRoleNames[i]] = true;
        }
    }

    modifier onlyExecutiveRole() {
        require(isExecutiveRole[memberTypeOf[msg.sender]], "Not an executive role");
        _;
    }

    modifier canMintCustomNFT() {
        // require is executive or is voting contract
        require(
            isExecutiveRole[memberTypeOf[msg.sender]] || msg.sender == electionContract,
            "Not an executive role or election contract"
        );
        _;
    }

    function setElectionContract(address _electionContract) public {
        require(electionContract == address(0), "Election contract already set");
        electionContract = _electionContract;
    }

    function setQuickJoin(address _quickJoin) public {
        require(!quickJoinSet, "QuickJoin already set");
        quickJoin = _quickJoin;
        quickJoinSet = true;
    }

    modifier onlyQuickJoin() {
        require(msg.sender == quickJoin, "Only QuickJoin can call this function");
        _;
    }

    function setMemberTypeImage(string memory memberTypeName, string memory imageURL) public {
        memberTypeImages[memberTypeName] = imageURL;
    }

    function checkMemberTypeByAddress(address user) public view returns (string memory) {
        require(bytes(memberTypeOf[user]).length > 0, "No member type found for user.");
        return memberTypeOf[user];
    }

    function checkIsExecutive(address user) public view returns (bool) {
        return isExecutiveRole[memberTypeOf[user]];
    }

    function mintNFT(address recipient, string memory memberTypeName) public canMintCustomNFT {
        require(bytes(memberTypeImages[memberTypeName]).length > 0, "Image for member type not set");
        string memory tokenURI = memberTypeImages[memberTypeName];
        uint256 tokenId = _nextTokenId++;
        _mint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI);
        memberTypeOf[recipient] = memberTypeName;
        emit mintedNFT(recipient, memberTypeName, tokenURI);
    }

    function changeMembershipType(address user, string memory newMemberType) public canMintCustomNFT {
        require(bytes(memberTypeImages[newMemberType]).length > 0, "Image for member type not set");
        memberTypeOf[user] = newMemberType;
        emit membershipTypeChanged(user, newMemberType);
    }

    function giveUpExecutiveRole() public onlyExecutiveRole {
        memberTypeOf[msg.sender] = DEFAULT_MEMBER_TYPE;
        emit membershipTypeChanged(msg.sender, DEFAULT_MEMBER_TYPE);
    }

    function removeMember(address user) public onlyExecutiveRole {
        require(bytes(memberTypeOf[user]).length > 0, "No member type found for user.");
        delete memberTypeOf[user];
        emit MemberRemoved(user);
    }

    function downgradeExecutive(address executive) public onlyExecutiveRole {
        require(isExecutiveRole[memberTypeOf[executive]], "User is not an executive.");
        console.log("lastDowngradeTime[msg.sender]: ", lastDowngradeTime[msg.sender]);
        console.log("block.timestamp: ", block.timestamp);
        require(
            block.timestamp >= lastDowngradeTime[msg.sender] + ONE_WEEK, "Downgrade limit reached. Try again in a week."
        );

        memberTypeOf[executive] = DEFAULT_MEMBER_TYPE;
        lastDowngradeTime[msg.sender] = block.timestamp;
        emit ExecutiveDowngraded(executive, msg.sender);
    }

    bool public firstMint = true;

    function mintDefaultNFT(address newUser) public onlyQuickJoin {
        require(bytes(memberTypeOf[newUser]).length == 0, "User is already a member.");
        string memory tokenURI = defaultImageURL;
        uint256 tokenId = _nextTokenId++;
        _mint(newUser, tokenId);
        _setTokenURI(tokenId, tokenURI);
        if (firstMint) {
            memberTypeOf[newUser] = "Executive";
            firstMint = false;
            emit mintedNFT(newUser, "Executive", tokenURI);
        } else {
            memberTypeOf[newUser] = DEFAULT_MEMBER_TYPE;
            emit mintedNFT(newUser, DEFAULT_MEMBER_TYPE, tokenURI);
        }
    }

    function getQuickJoin() public returns (address) {
        return quickJoin;
    }
}
