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
        portal = PortalMock(0xd0165c63EF975625b1E60c275304c725919784e9);
    }

    function mockUpgradeToDevVersion() public {
        RebornPortal newImpl = new PortalMock();
        // mock upgrade to new one
        vm.prank(portal.owner());
        portal.upgradeTo(address(newImpl));
    }

    function testSimulateClaimDrop() public {
        vm.rollFork(29132674);
        mockUpgradeToDevVersion();

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 97000000000000000035;

        vm.prank(0xfC50C0a67720489Db7a45097D7fE3cBEA673E441);

        portal.claimDrops(tokenIds);
    }

    function testSimulateInfuse() public {
        vm.selectFork(bnbMain);
        portal = PortalMock(0xdec218e6009716d9c5c4AAa3c3a46137605B8b39);

        vm.rollFork(27564051);
        mockUpgradeToDevVersion();

        uint256[] memory tokenIds = new uint256[](7);
        tokenIds[0] = 97000000000000000035;
        // tokenIds[1] = 97000000000000000037;
        // tokenIds[2] = 97000000000000000038;
        // tokenIds[3] = 97000000000000000030;
        // tokenIds[4] = 97000000000000000031;
        // tokenIds[5] = 97000000000000000034;
        // tokenIds[6] = 97000000000000000032;

        vm.prank(0x679658Be03475D0A5393c70ea0E9A1158Dfae1Ff);

        portal.infuse(
            56000000000000000014,
            25469892200298411315640594,
            TributeDirection.Forward
        );
    }
}
