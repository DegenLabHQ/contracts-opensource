// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {INFTManagerDefination} from "src/interfaces/nft/INFTManager.sol";

contract NFTManagerStorage is INFTManagerDefination {
    // latest index of metadata map
    uint16 public latestMetadataIdx;

    address public chainlinkVRFProxy;

    // white list merkle tree root
    bytes32 public merkleRoot;

    // Mapping from token ID to Properties
    mapping(uint256 => Properties) internal properties;

    mapping(address => bool) public signers;

    // record minted users to avoid whitelist users mint more than once
    mapping(address => bool) public minted;

    // id => metadata map
    mapping(uint256 => Properties) metadatas;

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

    string public baseURI;

    uint256[] private openFailedBoxs;

    uint256[48] private _gap;
}
