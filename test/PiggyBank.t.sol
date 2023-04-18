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
    address user1 = address(2);
    address user2 = address(3);

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
        deal(user1, 100 ether);
        deal(user2, 100 ether);
        uint256 season = 0;
        vm.expectEmit(true, true, true, true);
        emit Deposit(season, user1, 0, 0.08 ether, 0.18 ether);
        mockIncarnet(season, user1, 1 ether);

        vm.expectEmit(true, true, true, true);
        emit Deposit(season, user1, 0, 0.8 ether, 0.98 ether);
        mockIncarnet(season, user1, 10 ether);

        vm.expectEmit(true, true, true, true);
        emit Deposit(season, user1, 1, 0.78 ether, 0.78 ether);
        mockIncarnet(season, user1, 10 ether);

        mockIncarnet(season, user2, 1 ether);

        RoundInfo memory roundInfo = piggyBank.getRoundInfo(season);
        assertEq(roundInfo.currentIndex, 1);
        assertEq(roundInfo.totalAmount, 0.86 ether);
        assertEq(roundInfo.target, 1.02 ether);
    }

    function testClaimReward() public {
        testDeposit();
        vm.prank(owner);
        portal.mockStop(0);

        vm.expectEmit(true, true, true, true);
        emit ClaimedReward(0, user1, 1686976744186046511);
        vm.prank(user1);
        piggyBank.claimReward(0);

        vm.expectEmit(true, true, true, true);
        emit ClaimedReward(0, user2, 173023255813953488);
        vm.prank(user2);
        piggyBank.claimReward(0);
    }

    function mockIncarnet(uint256 season, address user, uint256 amount) public {
        vm.startPrank(user);
        portal.mockIncarnet{value: amount}(season, user);
        vm.stopPrank();
    }
}
