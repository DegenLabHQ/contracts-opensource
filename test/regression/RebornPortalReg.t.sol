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

    function testSimulateTributeRank() public {
        vm.rollFork(29262228);
        mockUpgradeToDevVersion();

        uint256[] memory rank = portal.getTvlRank();

        console2.log("tvl min value : ", portal.getMinScoreInRank());

        console2.log("TVL rank: ");
        for (uint256 i = 0; i < rank.length; ) {
            console2.log("rank: ", i + 1, "tokenId: ", rank[i]);

            unchecked {
                i++;
            }
        }

        console2.log(
            97000000000000000091,
            "tvl: ",
            portal.getTokenIdTVL(97000000000000000091)
        );
    }
}
