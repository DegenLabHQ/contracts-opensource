// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IPiggyBankDefination} from "src/interfaces/IPiggyBank.sol";
import {PiggyBank} from "src/PiggyBank.sol";
import {PortalMock} from "src/mock/PortalMock.sol";
import {RBT} from "src/RBT.sol";

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

contract PiggyBankTest is Test, IPiggyBankDefination {
    PiggyBank piggyBank;
    PortalMock portal;

    address owner = address(1);
    address user = address(2);

    function setUp() public {
        piggyBank = new PiggyBank();
        portal = new PortalMock();
        init();
    }

    function init() public {
        deal(owner, 10 ether);
        RBT rbt = new RBT();
        portal.initialize(rbt, owner, "Degen Tombstone", "RIP", address(11));
        piggyBank.initialize(owner, address(portal));

        vm.startPrank(owner);
        portal.setPiggyBank(piggyBank);
        portal.setPiggyBankFee(800);
        portal.initializeSeason{value: 0.1 ether}(0.1 ether, 1 ether);

        piggyBank.setMultiple(200);

        vm.stopPrank();
    }

    function testDeposit() public {
        deal(user, 100 ether);
        vm.startPrank(user);
        uint256 season = 0;
        vm.expectEmit(true, true, true, true);
        emit Deposit(season, user, 0, 0.08 ether, 0.18 ether);
        portal.mockIncarnet{value: 1 ether}(season, user);

        vm.expectEmit(true, true, true, true);
        emit Deposit(season, user, 0, 0.8 ether, 0.98 ether);
        portal.mockIncarnet{value: 10 ether}(season, user);

        vm.expectEmit(true, true, true, true);
        emit Deposit(season, user, 1, 0.78 ether, 0.78 ether);
        portal.mockIncarnet{value: 10 ether}(season, user);

        RoundInfo memory roundInfo = piggyBank.getRoundInfo(season);
        assertEq(roundInfo.currentIndex, 1);
        assertEq(roundInfo.totalAmount, 0.78 ether);
        assertEq(roundInfo.target, 1.02 ether);

        vm.stopPrank();
    }
}
