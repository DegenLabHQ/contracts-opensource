// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {UUPSUpgradeable} from "./oz/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
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

    function initialize(
        address owner_,
        address portal_,
        uint256 season,
        RoundInfo calldata roundInfo
    ) public payable initializer {
        if (portal_ == address(0) || owner_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }

        __Ownable_init(owner_);

        portal = portal;

        // initialize season roundInfo
        if (roundInfo.totalAmount != msg.value) {
            revert InvalidRoundInfo();
        }
        seasons[season].totalAmount = msg.value;
        rounds[season] = roundInfo;
        userInfo[msg.sender][season][roundInfo.currentIndex] = msg.value;
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

            emit Deposit(season, account, roundInfo.currentIndex, msg.value);
        }
    }

    function _toNextRound(
        address account,
        uint256 season,
        uint256 newRoundInitAmount
    ) internal {
        // update rounds
        RoundInfo storage roundInfo = rounds[season];
        roundInfo.currentIndex++;
        roundInfo.target = (roundInfo.target * multiple) / 100;
        roundInfo.totalAmount = newRoundInitAmount;

        // update userInfo
        userInfo[account][season][roundInfo.currentIndex] = newRoundInitAmount;

        emit Deposit(
            season,
            account,
            roundInfo.currentIndex,
            newRoundInitAmount
        );
    }

    function setMultiple(uint8 multiple_) external override onlyOwner {
        multiple = multiple_;

        emit SetNewMultiple(multiple_);
    }

    function setMinTimeLong(uint64 minTimeLong_) external override onlyOwner {
        minTimeLong = minTimeLong_;

        emit SetMinTimeLong(minTimeLong_);
    }

    function newSeason(uint256 season, uint256 startTime) external onlyPortal {
        if (seasons[season].startTime == 0) {
            seasons[season].startTime = startTime;
        }

        emit NewSeason(season, startTime);
    }

    function checkIsSeasonEnd(uint256 season) public view returns (bool) {
        bool isEnd = false;
        if (
            (block.timestamp > seasons[season].startTime + minTimeLong) &&
            (rounds[season].totalAmount < rounds[season].target) &&
            (block.timestamp - rounds[season].startTime) >= 3600
        ) {
            isEnd = true;
        }
        return isEnd;
    }

    modifier onlyPortal() {
        if (msg.sender != portal) {
            revert CallerNotPortal();
        }
        _;
    }
}
