// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IDegenNFT} from "src/interfaces/nft/IDegenNFT.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";

import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import {CommonError} from "src/lib/CommonError.sol";

contract DegenNFT is
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    ERC721AUpgradeable,
    IDegenNFT
{
    // Mapping from tokenId to Property
    mapping(uint256 => uint256) internal properties;

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
        address owner_ // upgrade owner
    ) public initializerERC721A initializer {
        __ERC721A_init(name_, symbol_);
        __Ownable_init_unchained(owner_);
    }

    function mint(address to, uint256 quantity) external onlyManager {
        _mint(to, quantity);
    }

    function burn(uint256 tokenId) external onlyManager {
        _burn(tokenId);
    }

    function setManager(address manager_) external onlyOwner {
        if (manager_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }
        manager = manager_;

        emit SetManager(manager_);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;

        emit SetBaseURI(baseURI_);
    }

    /**
     * @dev emit ERC4906 event to trigger all metadata update
     */
    function emitMetadataUpdate() external onlyOwner {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function setProperties(
        uint256 tokenId,
        Property memory property_
    ) external onlyManager {
        // encode property
        uint16 property = encodeProperty(property_);

        // storage property
        uint256 bucket = tokenId >> 4;
        uint256 mask = properties[bucket];
        mask |= uint256(property) << ((tokenId % 16) * 16);
        properties[bucket] = mask;

        emit SetProperties(property_);
        emit MetadataUpdate(tokenId);
    }

    function setBucket(uint256 bucket, uint256 mask) external onlyManager {
        properties[bucket] = mask;
    }

    function setLevel(uint256 tokenId, uint256 level) external onlyManager {
        levels[tokenId] = level;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function encodeProperty(
        Property memory property_
    ) public pure returns (uint16 property) {
        property = (property << 12) | property_.nameId;
        property = (property << 3) | property_.rarity;
        property = (property << 1) | property_.tokenType;
    }

    function decodeProperty(
        uint16 property
    ) public pure returns (uint16 nameId, uint16 rarity, uint16 tokenType) {
        nameId = (property >> 4) & 0x0fff;
        rarity = (property >> 1) & 0x07;
        tokenType = property & 0x01;
    }

    function getProperty(
        uint256 tokenId
    ) external view returns (Property memory) {
        uint256 bucket = tokenId >> 4;
        uint256 mask = properties[bucket];
        uint16 property = uint16((mask >> ((tokenId % 16) * 16)) & 0xffff);

        (uint16 nameId, uint16 rarity, uint16 tokenType) = decodeProperty(
            property
        );

        return Property({nameId: nameId, rarity: rarity, tokenType: tokenType});
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return string.concat(super.tokenURI(tokenId), ".json");
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

    function _checkManager() internal view {
        if (msg.sender != manager) {
            revert OnlyManager();
        }
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }
}
