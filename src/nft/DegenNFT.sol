// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "src/interfaces/nft/IDegenNFT.sol";
import "./DegenERC721URIStorageUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";

contract DegenNFT is
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    DegenERC721URIStorageUpgradeable,
    IDegenNFT
{
    // Mapping from tokenId to Property
    mapping(uint256 => uint16) internal properties;

    // NFTManager
    address public manager;

    string public baseURI;

    // Mapping tokenId to level
    mapping(uint256 => uint256) internal levels;

    uint256[46] private _gap;

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function initialize(
        string calldata name_,
        string calldata symbol_,
        address owner // upgrade owner
    ) public initializerERC721A initializer {
        __ERC721A_init(name_, symbol_);
        __ERC721URIStorage_init_unchained();
        __Ownable_init_unchained(owner);
    }

    function mint(address to, uint256 quantity) external onlyManager {
        _mint(to, quantity);
    }

    function burn(uint256 tokenId) external onlyManager {
        _burn(tokenId);
    }

    function setManager(address manager_) external onlyOwner {
        if (manager_ == address(0)) {
            revert ZeroAddressSet();
        }
        manager = manager_;

        emit SetManager(manager_);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;

        emit SetBaseURI(baseURI_);
    }

    function setProperties(
        uint256 tokenId,
        Property memory _property
    ) external onlyManager {
        uint16 property;
        property = (property << 12) | _property.nameId;
        property = (property << 3) | _property.rarity;
        property = (property << 1) | _property.tokenType;

        properties[tokenId] = property;
        emit SetProperties(_property);
    }

    function setLevel(uint256 tokenId, uint256 level) external onlyManager {
        levels[tokenId] = level;
    }

    function setTokenURI(
        uint256 tokenId,
        string memory tokenURI
    ) external onlyManager {
        _setTokenURI(tokenId, tokenURI);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function getProperty(
        uint256 tokenId
    ) external view returns (Property memory) {
        uint16 property = properties[tokenId];
        return
            Property({
                nameId: (property >> 4) & 0x0fff,
                rarity: (property >> 1) & 0x07,
                tokenType: property & 0x01
            });
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function nextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    function getLevel(uint256 tokenId) external view returns (uint256) {
        return levels[tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // tokenId start from 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    modifier onlyManager() {
        if (msg.sender != manager) {
            revert OnlyManager();
        }
        _;
    }
}
