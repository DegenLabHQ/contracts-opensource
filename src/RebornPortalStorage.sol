// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {RBT} from "src/RBT.sol";
import {RewardVault} from "src/RewardVault.sol";
import {BitMapsUpgradeable} from "./oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {SingleRanking} from "src/lib/SingleRanking.sol";
import {PortalLib} from "src/PortalLib.sol";
import {FastArray} from "src/lib/FastArray.sol";

contract RebornPortalStorage is IRebornDefination {
    uint256 internal _season;

    RBT public rebornToken;

    mapping(address => bool) public signers;

    mapping(address => uint32) internal rounds;

    uint256 internal idx;

    mapping(uint256 => LifeDetail) internal details;

    mapping(uint256 => SeasonData) internal _seasonData;

    mapping(address => address) internal referrals;
    PortalLib.ReferrerRewardFees public rewardFees;

    RewardVault public vault;

    BitMapsUpgradeable.BitMap internal _seeds;

    // airdrop config
    PortalLib.AirdropConf internal _dropConf;

    address public burnPool;

    PortalLib.VrfConf internal _vrfConf;

    // requestId =>
    mapping(uint256 => RequestStatus) internal _vrfRequests;

    FastArray.Data internal _pendingDrops;

    // extra reward to parent referrer
    uint256 internal _extraReward;

    // uesless var for backward compatibility
    bool internal _g;

    // season => user address => count
    mapping(uint256 => mapping(address => uint256)) internal _incarnateCounts;

    // max incarnation count
    uint256 internal _incarnateCountLimit;

    uint256 internal _stopBetaBlockNumber;

    // tokenId => character property
    mapping(uint256 => PortalLib.CharacterProperty)
        internal _characterProperties;

    // tokenId => token required
    mapping(uint256 => uint256) internal _forgeRequiredMaterials;

    /// @dev gap for potential variable
    uint256[27] private _gap;
}
