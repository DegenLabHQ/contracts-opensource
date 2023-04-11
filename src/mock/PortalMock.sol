// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "src/RebornPortal.sol";
import "src/lib/SingleRanking.sol";

contract PortalMock is RebornPortal {
    using SingleRanking for SingleRanking.Data;

    function getTvlRank() public view returns (uint256[] memory) {
        return _seasonData[_season]._tributeRank.get(0, 100);
    }

    function claimDrops(uint256[] calldata tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _claimPoolDrop(tokenIds[i]);
        }
    }
}
