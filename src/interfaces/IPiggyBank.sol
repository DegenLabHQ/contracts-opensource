// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IPiggyBank {
    struct SeasonInfo {
        uint256 totalAmount;
        bytes32 stopedHash;
        address verifySigner; // Used for verification the next time stop is called
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
    event SeasonStoped(uint256 season, uint256 stopTime);
    event SignerUpdate(address indexed signer, bool valid);
    event SetStopedHash(
        uint256 season,
        bytes32 stopedHash,
        address verifySigner
    );

    error CallerNotPortal();
    error InvalidRoundInfo();
    error SeasonOver();
    error InvalidSeason();
    error InvalidSignature();
    error ZeroAddressSet();
    error InvaliedSigner();

    function deposit(uint256 season, address account) external payable;

    function setMultiple(uint8 multiple_) external;

    function setMinTimeLong(uint64 minTimeLong_) external;

    function checkIsSeasonEnd(uint256 season) external view returns (bool);

    function newSeason(uint256 season, uint256 startTime) external;

    function setSeasonStopedHash(
        uint256 season,
        bytes32 stopedHash,
        address verifySigner
    ) external;

    function stop(uint256 season, bytes calldata signature) external;
}
