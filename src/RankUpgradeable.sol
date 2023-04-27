// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {RankingRedBlackTree} from "src/lib/RankingRedBlackTree.sol";
import {SingleRanking} from "src/lib/SingleRanking.sol";
import {RebornPortalStorage} from "src/RebornPortalStorage.sol";
import {BitMapsUpgradeable} from "./oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import {DegenRank} from "src/DegenRank.sol";

abstract contract RankUpgradeable is RebornPortalStorage {
    using SingleRanking for SingleRanking.Data;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    /**
     * @dev set tokenId to rank, only top 100 into rank
     * @param tokenId incarnation tokenId
     * @param value incarnation life score
     */
    function _enterScoreRank(uint256 tokenId, uint256 value) internal {
        DegenRank._enterScoreRank(_seasonData[_season], tokenId, value);
    }

    /**
     * @dev set a new value in tree, only save top x largest value
     * @param value new value enters in the tree
     */
    function _enterTvlRank(uint256 tokenId, uint256 value) internal {
        DegenRank._enterTvlRank(
            _seasonData[_season]._tributeRank,
            _seasonData[_season]._isTopHundredScore,
            _seasonData[_season]._oldStakeAmounts,
            tokenId,
            value
        );
    }
}
