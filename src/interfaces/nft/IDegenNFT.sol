// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {IERC4906} from "src/interfaces/nft/IERC4906.sol";

interface IDegenNFTDefination is IERC4906 {
    struct Property {
        uint16 nameId;
        uint16 rarity;
        uint16 tokenType;
    }

    error OnlyManager();

    event SetManager(address manager);
    event SetBaseURI(string baseURI);
}

interface IDegenNFT is IDegenNFTDefination {
    function mint(address to, uint256 quantity) external;

    function burn(uint256 tokenId) external;

    function setBaseURI(string calldata baseURI_) external;

    function setLevel(uint256 tokenId, uint256 level) external;

    function totalMinted() external view returns (uint256);

    function getProperty(
        uint256 tokenId
    ) external view returns (Property memory);

    function exists(uint256 tokenId) external view returns (bool);

    function nextTokenId() external view returns (uint256);

    function getLevel(uint256 tokenId) external view returns (uint256);
}
