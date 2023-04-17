// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {UUPSUpgradeable} from "./oz/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ECDSAUpgradeable} from "./oz/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {SafeOwnableUpgradeable} from "./utils/SafeOwnableUpgradeable.sol";
import {CommonError} from "./lib/CommonError.sol";
import {IPiggyBank} from "./interfaces/IPiggyBank.sol";

contract PiggyBank is SafeOwnableUpgradeable, UUPSUpgradeable, IPiggyBank {
    address public portal;

    // nextRoundTarget = preRoundTarget * multiple / 100
    uint8 public multiple;

    // min time long from season start to end
    uint64 public minTimeLong;

    // Mapping from season to seasonInfo
    mapping(uint256 => SeasonInfo) seasons;

    // Mapping from round index to RoundInfo
    mapping(uint256 => RoundInfo) rounds;

    // mapping(account => mappiing(season=> mapping(roundIndex => userInfo)))
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) userInfo;

    uint256[46] internal _gap;

    function initialize(address owner_, address portal_) public initializer {
        if (portal_ == address(0) || owner_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }

        __Ownable_init(owner_);

        portal = portal;
    }

    function initializeSeason(
        uint256 season,
        uint32 seasonStartTime,
        RoundInfo calldata roundInfo
    ) external payable onlyPortal {
        // initialize season roundInfo
        if (roundInfo.totalAmount != msg.value) {
            revert InvalidRoundInfo();
        }
        seasons[season].totalAmount = msg.value;
        seasons[season].startTime = seasonStartTime;
        rounds[season] = roundInfo;

        emit InitializeSeason(season, seasonStartTime, roundInfo);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function deposit(
        uint256 season,
        address account
    ) external payable override onlyPortal {
        bool isEnd = checkIsSeasonEnd(season);
        if (isEnd) {
            if (!seasons[season].stoped) {
                seasons[season].stoped = true;
            }
            revert SeasonOver();
        }

        seasons[season].totalAmount += msg.value;

        // update round info
        RoundInfo storage roundInfo = rounds[season];
        if (roundInfo.totalAmount + msg.value > roundInfo.target) {
            uint256 newRoundInitAmount = msg.value -
                (roundInfo.target - roundInfo.totalAmount);
            _toNextRound(account, season, newRoundInitAmount);
        } else {
            roundInfo.totalAmount += msg.value;
            userInfo[account][season][roundInfo.currentIndex] += msg.value;

            emit Deposit(
                season,
                account,
                roundInfo.currentIndex,
                msg.value,
                roundInfo.totalAmount
            );
        }
    }

    function newSeason(uint256 season, uint256 startTime) external onlyPortal {
        if (seasons[season].startTime == 0) {
            seasons[season].startTime = uint32(startTime);
        }

        emit NewSeason(season, startTime);
    }

    function stop(uint256 season) external override onlyPortal {
        if (seasons[season].startTime == 0) {
            revert InvalidSeason();
        }
        seasons[season].stoped = true;

        emit SeasonStoped(season, block.timestamp);
    }

    function setMultiple(uint8 multiple_) external override onlyOwner {
        multiple = multiple_;

        emit SetNewMultiple(multiple_);
    }

    function setMinTimeLong(uint64 minTimeLong_) external override onlyOwner {
        minTimeLong = minTimeLong_;

        emit SetMinTimeLong(minTimeLong_);
    }

    function setSeasonStopedHash(
        uint256 season,
        bytes32 stopedHash,
        address verifySigner
    ) external override onlyOwner {
        if (seasons[season].startTime == 0) {
            revert InvalidSeason();
        }
        if (verifySigner == address(0)) {
            revert ZeroAddressSet();
        }

        seasons[season].stopedHash = stopedHash;
        seasons[season].verifySigner = verifySigner;

        emit SetStopedHash(season, stopedHash, verifySigner);
    }

    function _toNextRound(
        address account,
        uint256 season,
        uint256 nextRoundInitAmount
    ) internal {
        // update rounds
        RoundInfo storage roundInfo = rounds[season];
        roundInfo.currentIndex++;
        roundInfo.target = (roundInfo.target * multiple) / 100;

        if (nextRoundInitAmount > roundInfo.target) {
            // update userInfo
            userInfo[account][season][roundInfo.currentIndex] = roundInfo
                .target;
            emit Deposit(
                season,
                account,
                roundInfo.currentIndex,
                roundInfo.target,
                roundInfo.target
            );

            _toNextRound(
                account,
                season,
                nextRoundInitAmount - roundInfo.target
            );
        } else {
            roundInfo.totalAmount = nextRoundInitAmount;

            userInfo[account][season][
                roundInfo.currentIndex
            ] = nextRoundInitAmount;

            emit Deposit(
                season,
                account,
                roundInfo.currentIndex,
                nextRoundInitAmount,
                nextRoundInitAmount
            );
        }
    }

    function checkIsSeasonEnd(uint256 season) public view returns (bool) {
        bool isEnd = false;

        bool isAutoEnd = ((block.timestamp >
            seasons[season].startTime + minTimeLong) &&
            (rounds[season].totalAmount < rounds[season].target) &&
            (block.timestamp - rounds[season].startTime) >= 3600);

        if (isAutoEnd || seasons[season].stoped) {
            isEnd = true;
        }
        return isEnd;
    }

    function verifyStopHash(
        uint256 season,
        bytes calldata signature
    ) public view returns (bool) {
        bytes32 messageHash = ECDSAUpgradeable.toEthSignedMessageHash(
            seasons[season].stopedHash
        );
        address signer = ECDSAUpgradeable.recover(messageHash, signature);
        return signer == seasons[season].verifySigner;
    }

    modifier onlyPortal() {
        if (msg.sender != portal) {
            revert CallerNotPortal();
        }
        _;
    }
}