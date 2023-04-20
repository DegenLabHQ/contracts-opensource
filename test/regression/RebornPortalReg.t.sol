// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "src/deprecated/DeprecatedRBT.sol";
import "src/RBT.sol";
import "src/RebornPortal.sol";
import {PortalLib} from "src/PortalLib.sol";

import {PortalMock} from "src/mock/PortalMock.sol";
import "src/interfaces/IPiggyBank.sol";

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";

/**
 * @notice this file can be edited freely if the whole test can not pass
 */
contract RebornPortalReg is Test, IRebornDefination, IPiggyBankDefination {
    uint256 bnbTest;
    uint256 bnbMain;
    PortalMock portal;

    function setUp() public {
        string memory bnbTestRpcUrl = vm.envString("BNB_CHAIN_TEST_URL");
        string memory bnbMainRpcUrl = vm.envString("BNB_CHAIN_URL");
        bnbTest = vm.createFork(bnbTestRpcUrl);
        bnbMain = vm.createFork(bnbMainRpcUrl);
        vm.selectFork(bnbTest);
        portal = PortalMock(0x82724f06EA5cdeb574b84316c6d84A1362a41B61);
    }

    function mockUpgradeToDevVersion() public {
        RebornPortal newImpl = new PortalMock();
        // mock upgrade to new one
        vm.prank(portal.owner());
        portal.upgradeTo(address(newImpl));
    }

    function testSimulatePerformUpKeep() public {
        vm.rollFork(27913896);
        mockUpgradeToDevVersion();

        // portal.performUpkeep(abi.encode(1, 0));
    }

    function testSimulateForging() public {
        portal = PortalMock(0xc999E375924F634ade6686831195540bBCC02C34);
        vm.rollFork(29074010);
        vm.warp(0);
        mockUpgradeToDevVersion();

        vm.prank(0x4E574D7015E34235749F9406507B5471B5bf8BBd);

        portal.forging(1238, 2);
    }
}
