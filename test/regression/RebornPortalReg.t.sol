// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "src/deprecated/DeprecatedRBT.sol";
import "src/RBT.sol";
import "src/RebornPortal.sol";

import "src/mock/PortalMock.sol";

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

/**
 * @notice this file can be edited freely if the whole test can not pass
 */
contract RebornPortalReg is Test {
    uint256 bnbTest;
    uint256 bnbMain;
    PortalMock portal;

    function setUp() public {
        string memory bnbTestRpcUrl = vm.envString("BNB_CHAIN_TEST_URL");
        string memory bnbMainRpcUrl = vm.envString("BNB_CHAIN_URL");
        bnbTest = vm.createFork(bnbTestRpcUrl);
        bnbMain = vm.createFork(bnbMainRpcUrl);
        vm.selectFork(bnbTest);
        portal = PortalMock(0xF6D95a75464B0C2C717407867eEF377ab1fe7046);
    }

    function mockUpgradeToDevVersion() public {
        RebornPortal newImpl = new PortalMock();
        // mock upgrade to new one
        vm.prank(portal.owner());
        portal.upgradeTo(address(newImpl));
    }

    function testPerformUpkeep() public {
        portal = PortalMock(0xA751c9Ad92472D1E4eb6B6F9803311E22C5FbA9F);
        vm.selectFork(bnbMain);
        vm.rollFork(26540827);
        (bool up, bytes memory b) = portal.checkUpkeep(abi.encode(0));
        portal.performUpkeep(b);
    }

    function testSimulateGetTvlRankCaseOne() public {
        portal = PortalMock(0xA751c9Ad92472D1E4eb6B6F9803311E22C5FbA9F);
        vm.selectFork(bnbMain);
        vm.rollFork(26594100);
        mockUpgradeToDevVersion();

        uint256[] memory ranks = portal.getTvlRank();

        bool hasTokenId;
        for (uint256 i = 0; i < ranks.length; i++) {
            if (ranks[i] == 56000000000000013610) {
                hasTokenId = true;
            }
        }
        assertEq(hasTokenId, true);
        assertEq(ranks.length, 100);
    }

    function testSimulateGetTvlRankCaseTwo() public {
        portal = PortalMock(0xA751c9Ad92472D1E4eb6B6F9803311E22C5FbA9F);
        vm.selectFork(bnbMain);
        vm.rollFork(26594101);
        mockUpgradeToDevVersion();

        uint256[] memory ranks = portal.getTvlRank();

        for (uint256 i = 0; i < ranks.length; i++) {
            if (ranks[i] == 56000000000000013610) {
                revert("Exit Rank Fail");
            }
        }
        assertEq(ranks.length, 100);
    }

    function testSimulateAntiCheatCaseOne() public {
        portal = PortalMock(0xA751c9Ad92472D1E4eb6B6F9803311E22C5FbA9F);
        vm.selectFork(bnbMain);
        vm.rollFork(26542903);
        mockUpgradeToDevVersion();

        vm.startPrank(portal.owner());
        portal.antiCheat(56000000000000004072, 149019);
        portal.antiCheat(56000000000000004081, 149019);

        vm.stopPrank();
    }

    function testSimulateAntiCheatCaseTwo() public {
        portal = PortalMock(0xA751c9Ad92472D1E4eb6B6F9803311E22C5FbA9F);
        vm.selectFork(bnbMain);
        vm.rollFork(26575852);
        mockUpgradeToDevVersion();

        vm.startPrank(portal.owner());
        portal.antiCheat(56000000000000013610, 71);
        portal.antiCheat(56000000000000013260, 38);
        portal.antiCheat(56000000000000014148, 17);
        portal.antiCheat(56000000000000013192, 18);
        portal.antiCheat(56000000000000013234, 31);
        portal.antiCheat(56000000000000013695, 34);
        portal.antiCheat(56000000000000013848, 23);
        portal.antiCheat(56000000000000013417, 167);
        portal.antiCheat(56000000000000013282, 31);
        portal.antiCheat(56000000000000013396, 38);
        portal.antiCheat(56000000000000013224, 22);
        portal.antiCheat(56000000000000013068, 79);
        portal.antiCheat(56000000000000013936, 47);
        portal.antiCheat(56000000000000013509, 308);

        vm.stopPrank();
    }

    function testSimulatePendingDrop() public {
        vm.selectFork(bnbMain);
        portal = PortalMock(0xA751c9Ad92472D1E4eb6B6F9803311E22C5FbA9F);
        vm.rollFork(26550446);
        mockUpgradeToDevVersion();
        uint256[] memory arr = new uint256[](1);
        (arr[0]) = (56000000000000005954);
        vm.startPrank(0x4083041Be3E2a7657724b5f7d088C0abEEDCdB33);
        (uint256 n, uint256 t) = portal.pendingDrop(arr);
        assertEq(n, 23545723434902000);
        assertEq(t, 160033661380102754324);

        vm.expectEmit(true, true, true, true);
        emit PortalLib.ClaimRebornDrop(
            56000000000000005954,
            160033661380102754324
        );
        emit PortalLib.ClaimNativeDrop(56000000000000005954, 23545723434902000);

        portal.claimDrops(arr);
        vm.stopPrank();
    }

    function testClaimRebornDrop() public {
        vm.rollFork(27708623);

        mockUpgradeToDevVersion();

        uint256[] memory arr = new uint256[](4);
        (arr[0], arr[1], arr[2], arr[3]) = (
            97000000000000000015,
            97000000000000000011,
            97000000000000000013,
            97000000000000000010
        );

        vm.expectEmit(false, false, false, false);
        emit PortalLib.ClaimRebornDrop(97000000000000000015, 0);
        emit PortalLib.ClaimRebornDrop(97000000000000000011, 0);
        emit PortalLib.ClaimRebornDrop(97000000000000000013, 0);
        emit PortalLib.ClaimRebornDrop(97000000000000000010, 0);

        vm.prank(0x679658Be03475D0A5393c70ea0E9A1158Dfae1Ff);
        portal.claimRebornDrops(arr);
    }

    function testSimulatePerformUpKeep() public {
        vm.rollFork(27913896);
        mockUpgradeToDevVersion();

        // portal.performUpkeep(abi.encode(1, 0));
    }
}
