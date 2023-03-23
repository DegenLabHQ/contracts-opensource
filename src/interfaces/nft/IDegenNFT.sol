// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

interface IDegenNFTDefination is IERC721AUpgradeable {
    enum Rarity {
        Legendary,
        Epic,
        Rare,
        Uncommon,
        Common
    }

    enum TokenType {
        Standard,
        Shard
    }

    struct Property {
        string name;
        Rarity rarity;
        TokenType tokenType;
    }

    error ZeroAddressSet();
    error OnlyManager();

    event SetManager(address manager);
    event SetProperties(Property properties);
    event SetBaseURI(string baseURI);
}

interface IDegenNFT is IDegenNFTDefination {
    function mint(address to, uint256 quantity) external;

    function burn(uint256 tokenId) external;

    function setBaseURI(string calldata baseURI_) external;

    function setProperties(
        uint256 tokenId,
        Property memory _properties
    ) external;

    function setLevel(uint256 level_) external;

    function setTokenURI(uint256 tokenId, string memory tokenURI) external;

    function totalMinted() external view returns (uint256);

    function getProperty(
        uint256 tokenId
    ) external view returns (Property memory);

    function exists(uint256 tokenId) external view returns (bool);

    function nextTokenId() external view returns (uint256);
}
