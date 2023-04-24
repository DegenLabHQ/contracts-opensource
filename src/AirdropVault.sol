// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IAirdropVault} from "src/interfaces/IAirdropVault.sol";

contract AirdropVault is IAirdropVault, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable rebornToken;

    /**
     * @dev receive native token
     */
    receive() external payable {}

    constructor(address owner_, address rebornToken_) {
        if (rebornToken_ == address(0)) revert ZeroAddressSet();
        _transferOwnership(owner_);
        rebornToken = rebornToken_;
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function rewardDegen(
        address to,
        uint256 amount
    ) external virtual override onlyOwner {
        IERC20(rebornToken).safeTransfer(to, amount);
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function rewardNative(
        address to,
        uint256 amount
    ) external virtual override nonReentrant onlyOwner {
        payable(to).transfer(amount);
    }

    /**
     * @notice withdraw token Emergency
     */
    function withdrawEmergency(address to) external virtual override onlyOwner {
        if (to == address(0)) revert ZeroAddressSet();
        uint256 degenBalance = IERC20(rebornToken).balanceOf(address(this));
        uint256 nativeBalance = address(this).balance;
        IERC20(rebornToken).safeTransfer(to, degenBalance);

        payable(to).transfer(nativeBalance);

        emit WithdrawEmergency(to, rebornToken, degenBalance, nativeBalance);
    }
}
