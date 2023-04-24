// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "src/RebornPortal.sol";
import "src/lib/SingleRanking.sol";

contract PortalMock is RebornPortal {
    using SingleRanking for SingleRanking.Data;

    function getSeason() public view returns (uint256) {
        return _season;
    }

    function getTvlRank() public view returns (uint256[] memory) {
        return _seasonData[_season]._tributeRank.get(0, 100);
    }

    function mockIncarnet(
        uint256 season,
        address account,
        uint256 amount
    ) external payable {
        uint256 value = (msg.value * piggyBankFee) / PortalLib.PERCENTAGE_BASE;
        piggyBank.deposit{value: value}(season, account, amount);
    }

    function mockStop(uint256 season) external {
        piggyBank.stop(season);
    }

    function setNativeDropLock(bool lock) public {
        _dropConf._lockRequestDropNative = lock;
    }

    function setDegenDropLock(bool lock) public {
        _dropConf._lockRequestDropReborn = lock;
    }

    function getNativeDropLock() public view returns (bool) {
        return _dropConf._lockRequestDropNative;
    }

    function getDegenDropLock() public view returns (bool) {
        return _dropConf._lockRequestDropReborn;
    }
}
