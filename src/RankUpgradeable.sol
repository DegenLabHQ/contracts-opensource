// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {RankingRedBlackTree} from "src/lib/RankingRedBlackTree.sol";
import {SingleRanking} from "src/lib/SingleRanking.sol";

contract RankUpgradeable {
    error RequireLengthExceedCurrentData();
    error InsufficientData();
    error ZeroValueEnter();

    using SingleRanking for SingleRanking.Data;
    SingleRanking.Data private _rank;
    uint256 private _treeLength;
    mapping(uint256 => uint256) _tokenIdOldValue;

    // index id => tokenid
    mapping(uint256 => uint256) internal _rankIndexMap;

    /**
     * @dev set a new value in tree, only save top x largest value
     * @param value new value enters in the tree
     */
    function enter(uint256 tokenId, uint256 value) public {
        if (value == 0) {
            revert ZeroValueEnter();
        }

        if (_tokenIdOldValue[tokenId] != 0) {
            _rank.remove(tokenId, _tokenIdOldValue[tokenId]);
        }
        _rank.add(tokenId, value);
        _tokenIdOldValue[tokenId] = value;
    }

    // function getTopNIndex(
    //     uint256 n
    // ) public view returns (uint256[] memory indexes) {
    //     if (_tree.counter <= n) {
    //         revert InsufficientData();
    //     }

    //     indexes = new uint256[](n);

    //     for (uint256 i = 0; i < n; i++) {
    //         (indexes[i], ) = _tree.lastByOffset(i + 1);
    //     }
    // }

    function getTopNValue(
        uint256 n
    ) public view returns (uint256[] memory values) {
        return _rank.get(0, n);
    }
}
