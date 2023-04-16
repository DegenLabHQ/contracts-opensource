// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IPiggyBank {
    struct SeasonInfo {
        uint256 totalAmount;
        bytes32 stopedHash;
        uint64 startTime;
        bool stoped;
    }

    struct RoundInfo {
        uint256 totalAmount;
        uint256 target;
        uint256 currentIndex;
        uint256 startTime;
    }

    event SetNewMultiple(uint8 multiple);
    event SetMinTimeLong(uint64 minTimeLong);
    event NewSeason(uint256 season, uint256 startTime);
    event Deposit(
        uint256 season,
        address account,
        uint256 roundIndex,
        uint256 amount
    );

    error CallerNotPortal();
    error InvalidRoundInfo();
    error SeasonOver();

    function deposit(uint256 season, address account) external payable;

    function setMultiple(uint8 multiple_) external;

    function setMinTimeLong(uint64 minTimeLong_) external;

    function checkIsSeasonEnd(uint256 season) external view returns (bool);

    function newSeason(uint256 season, uint256 startTime) external;
}
