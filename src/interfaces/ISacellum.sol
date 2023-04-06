// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface ISacellumDef {
    event RateSet(uint256 rate);
    event Invoke(uint256 amountBurn, uint256 amountGet);
    event Withdraw(address to, uint256 amount);
    error RateNotSet();
}

interface ISacellum is ISacellumDef {
    function setRate(uint256 rate_) external;

    function invoke(uint256 amount) external;
}
