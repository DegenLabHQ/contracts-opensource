// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "test/portal/RebornPortalBase.t.sol";

import {PortalLib} from "src/PortalLib.sol";

import "forge-std/console2.sol";

import "src/AirdropVault.sol";

// import "test/TestUtils.sol";

contract AirdropVaultTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 value);

    address internal _owner = vm.addr(9);
    AirdropVault internal _vault;
    RBT internal _rbt;

    function setUp() public {
        _rbt = TestUtils.deployRBT(_owner);
        _vault = new AirdropVault(_owner, address(_rbt));
    }

    function testShouldAirdropVaultReceiveNativeToken(uint256 amount) public {
        vm.assume(amount < address(msg.sender).balance);
        payable(address(_vault)).transfer(amount);
    }

    function testShouldOwnerRewardNativeSuccess(
        address user,
        uint256 amount
    ) public {
        vm.assume(user.code.length == 0 && uint160(user) > 20);
        vm.deal(user, 0);
        vm.deal(address(_vault), amount);
        vm.prank(_owner);
        _vault.rewardNative(user, amount);
        assertEq(user.balance, amount);
    }

    function testShouldOwnerRewardDegenSuccess(
        address user,
        uint256 amount
    ) public {
        deal(address(_rbt), user, 0);
        deal(address(_rbt), address(_vault), amount);
        vm.prank(_owner);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(_vault), user, amount);

        _vault.rewardDegen(user, amount);
        assertEq(_rbt.balanceOf(user), amount);
    }

    function testShouldWithdrawEmergencySuccess(uint256 nativeAmount, uint256 degenAmount) public {
        deal(address(_rbt), address(_vault), degenAmount);
        deal(address(_vault), nativeAmount);

        // vm
    }
}
