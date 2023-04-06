// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "test/TestUtils.sol";

import "src/RBT.sol";
import "src/Sacellum.sol";
import "src/interfaces/ISacellum.sol";

contract SacellumTest is Test, ISacellumDef {
    RBT cz;
    RBT degen;
    Sacellum sa;
    address _owner = address(2);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        cz = TestUtils.deployRBT(_owner);
        degen = TestUtils.deployRBT(_owner);
        sa = deploySacellum();
    }

    function deploySacellum() public returns (Sacellum) {
        Sacellum con = new Sacellum();
        con.initialize(cz, degen, _owner);
        return con;
    }

    function testInvokeWithZeroRateFail(uint256 amount) public {
        vm.expectRevert(RateNotSet.selector);
        vm.prank(_owner);
        sa.invoke(amount);
    }

    function testOwnerCanSetRate(uint256 rate) public {
        vm.expectEmit(true, true, true, true);
        emit RateSet(rate);
        vm.prank(_owner);
        sa.setRate(rate);
    }

    function testNoOwnerCannotSetRate(address caller, uint256 rate) public {
        vm.assume(caller != _owner);
        vm.expectRevert();
        vm.prank(caller);
        sa.setRate(rate);
    }

    function testInvokeSuccess(
        address user,
        uint256 rateSeed,
        uint256 CZAmountSeed
    ) public {
        vm.assume(user != address(0));
        uint256 rate = bound(rateSeed, 1, 10e9);
        uint256 CZAmount = bound(CZAmountSeed, 0, type(uint128).max);
        mockSetRate(rate);

        deal(address(cz), user, UINT256_MAX);
        deal(address(degen), address(sa), UINT256_MAX);

        vm.expectEmit(true, true, true, true);

        emit Transfer(user, address(0), CZAmount);
        emit Transfer(address(sa), user, CZAmount * rate);
        emit Invoke(CZAmount, CZAmount * rate);

        vm.startPrank(user);
        cz.approve(address(sa), UINT256_MAX);
        sa.invoke(CZAmount);
        vm.stopPrank();
    }

    function testOwnerCanWithdraw(uint256 amount) public {
        deal(address(degen), address(sa), amount);
        deal(address(degen), sa.owner(), 0);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(sa.owner(), amount);

        vm.startPrank(sa.owner());
        sa.withdrawRemaining(sa.owner());
        vm.stopPrank();

        assertEq(degen.balanceOf(sa.owner()), amount);
    }

    function testNotOwnerCannotWithdraw(address caller, uint256 amount) public {
        vm.assume(caller != sa.owner());

        deal(address(degen), address(sa), amount);

        vm.expectRevert();
        vm.prank(caller);
        sa.withdrawRemaining(caller);
    }

    function mockSetRate(uint256 rate) public {
        vm.prank(_owner);
        sa.setRate(rate);
    }
}
