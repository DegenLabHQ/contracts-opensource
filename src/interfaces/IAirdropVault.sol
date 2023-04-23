// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IAirdropVault {
    error ZeroAddressSet();

    function rewardDegen(address to, uint256 amount) external; // send degen reward

    function rewardNative(address to, uint256 amount) external; // send native reward

    function withdrawEmergency(address to) external;

    event WithdrawEmergency(
        address degenToken,
        uint256 degenAmount,
        uint256 nativeAmount
    );
}
