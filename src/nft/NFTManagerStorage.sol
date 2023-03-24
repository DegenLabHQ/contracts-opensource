// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {INFTManagerDefination} from "src/interfaces/nft/INFTManager.sol";
import {IDegenNFT, IDegenNFTDefination} from "src/interfaces/nft/IDegenNFT.sol";

contract NFTManagerStorage is INFTManagerDefination {
    // degen nft address
    IDegenNFT public degenNFT;

    // chainlink vrf proxy address
    address public chainlinkVRFProxy;

    // latest index of metadata map
    uint16 public latestMetadataIdx;

    // white list merkle tree root
    bytes32 public merkleRoot;

    mapping(address => bool) public signers;

    // record minted users to avoid whitelist users mint more than once
    // mapping(address => bool) public minted;
    BitMapsUpgradeable.BitMap internal hasMinted;

    // id => metadata map
    mapping(uint256 => IDegenNFTDefination.Property) metadatas;

    // Mapping from requestId to tokenId
    mapping(uint256 => uint256) requestIdToTokenId;

    // Mapping metadataId to wether has been bind to NFT
    mapping(uint256 => bool) metadataUsed;

    // Mapping from tokenId to wether has been bind metadata
    mapping(uint256 => bool) opened;

    // Mapping from mint type to mint start and end time
    mapping(MintType => MintTime) mintTime;

    // different config with different level, index as level
    BurnRefundConfig[] internal burnRefundConfigs;

    // public mint pay mint fee
    uint256 public mintFee;

    uint256[] private openFailedBoxs;

    uint256[48] private _gap;
}
