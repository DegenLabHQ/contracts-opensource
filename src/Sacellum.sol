// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {RBT} from "src/RBT.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {ISacellum} from "src/interfaces/ISacellum.sol";

contract Sacellum is
    ISacellum,
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable
{
    RBT public CZToken;
    RBT public DEGENToken;
    uint256 public rate;

    uint256[47] private _gap;

    /**
     * @dev initialize function
     * @param CZToken_ $CZ token address
     * @param DEGENToken_ $DEGEN token address
     * @param owner_ contract owner
     */
    function initialize(
        RBT CZToken_,
        RBT DEGENToken_,
        address owner_
    ) public initializer {
        if (
            address(CZToken_) == address(0) ||
            address(DEGENToken_) == address(0)
        ) {
            revert CommonError.ZeroAddressSet();
        }
        CZToken = CZToken_;
        DEGENToken = DEGENToken_;
        __Ownable_init(owner_);
        __Pausable_init();
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev set invoke reate
     * @param rate_ $DEGEN amount per $CZ
     */
    function setRate(uint256 rate_) external override onlyOwner {
        rate = rate_;
        emit RateSet(rate);
    }

    /**
     * @dev burn $CZ to invoke for $DEGEN
     * @param amount amount of $CZ to be burned
     */
    function invoke(uint256 amount) external override {
        if (rate == 0) {
            revert RateNotSet();
        }
        CZToken.burnFrom(msg.sender, amount);
        uint256 degenAmount = amount * rate;
        DEGENToken.transfer(msg.sender, degenAmount);

        emit Invoke(amount, degenAmount);
    }
}
