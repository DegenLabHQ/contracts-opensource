// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "src/deprecated/DeprecatedRBT.sol";
import "src/RBT.sol";
import {RebornPortal} from "src/RebornPortal.sol";
import {PortalLib} from "src/PortalLib.sol";

import {PortalMock} from "src/mock/PortalMock.sol";

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";

/**
 * @notice this file can be edited freely if the whole test can not pass
 */
contract RebornPortalReg is Test, IRebornDefination {
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

    function testSimulateIncarnateWithChar() public {
        vm.rollFork(28870846);
        mockUpgradeToDevVersion();

        InnateParams memory innateParams = InnateParams(
            13910000000000000,
            417300000000000000000000,
            10000000000000000,
            26670000000000000,
            800100000000000000000000
        );
        CharParams memory charParams = CharParams(
            714,
            1681303348,
            0x9427e6840d26c8fc80476ef0f8e7df104feb7deba98fffa4b7b559f9738f5058,
            0x67c6bfa90acba928129d7750e44d5d5e15d65aa906e72049d82b900b3b31d7eb,
            28
        );

        vm.prank(0x850Fe27f63de12b601C0203b62d7995462D1D1Bc);
        portal.incarnate(innateParams, address(0), charParams);
    }
}
