// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "test/portal/RebornPortal.t.sol";
import {InvariantTest} from "forge-std/InvariantTest.sol";

import "test/portal/handler/DropHandler.sol";

contract AirdropInvar is RebornPortalBaseTest, InvariantTest {
    DropHandler internal _dropHandler;

    function setUp() public override deployAll {
        _dropHandler = new DropHandler(portal, rbt, _vrfCoordinator, _signer);
        targetContract(address(_dropHandler));
    }

    function invariant_DropRebornShouldMatch() public {
        uint256 totalAmount = _dropHandler.dropCount() *
            ((uint256(portal.getDropConf()._rebornTopEthAmount) *
                1 ether *
                10) +
                (uint256(portal.getDropConf()._rebornRaffleEthAmount) *
                    1 ether *
                    10));

        // 80% to staker should match
        uint256 StakerAmount;
        // top 100 tokenId should be 101 - 200
        for (uint256 i = 0; i < 220; i++) {
            console.log(
                "tokenId: ",
                i,
                "amount: ",
                (portal.getPool(i).coindayCumulant *
                    portal.getPool(i).accRebornPerShare) /
                    PortalLib.PERSHARE_BASE
            );
            StakerAmount +=
                (portal.getPool(i).coindayCumulant *
                    portal.getPool(i).accRebornPerShare) /
                PortalLib.PERSHARE_BASE;
        }
        assertApproxEqAbs((totalAmount * 4) / 5, StakerAmount, 1000);

        // 20% to owner should match
        uint256 OwnerAmount;
        // top 100 tokenId should be 1 - 200
        for (uint256 i = 1; i < 201; i++) {
            OwnerAmount += portal
                .getPortfolio(portal.ownerOf(i), i)
                .pendingOwnerRebornReward;
        }
        assertApproxEqAbs((totalAmount * 1) / 5, OwnerAmount, 1000);
    }

    function invariant_DropNativeShouldMatch() public {
        uint256 totalRatio = ((uint256(
            portal.getDropConf()._nativeTopDropRatio
        ) * 10) + (uint256(portal.getDropConf()._nativeRaffleDropRatio) * 10));

        // calculate airdropped amount of native token
        uint256 totalAmount;
        uint256 initAmount = _dropHandler.initalJackPot();
        for (uint256 i = 0; i < _dropHandler.dropCount(); i++) {
            uint256 newAmount = (initAmount * totalRatio) /
                PortalLib.PERCENTAGE_BASE;

            totalAmount += newAmount;

            initAmount -= newAmount;
        }

        // 80% to staker should match
        uint256 StakerAmount;
        // top 100 tokenId should be 101 - 200
        for (uint256 i = 0; i < 220; i++) {
            StakerAmount +=
                (portal.getPool(i).totalAmount *
                    portal.getPool(i).accNativePerShare) /
                PortalLib.PERSHARE_BASE;
        }

        assertApproxEqAbs((totalAmount * 4) / 5, StakerAmount, 1000);

        // 20% to owner should match
        uint256 OwnerAmount;
        // top 100 tokenId should be 1 - 200
        for (uint256 i = 1; i < 201; i++) {
            OwnerAmount += portal
                .getPortfolio(portal.ownerOf(i), i)
                .pendingOwnerNativeReward;
        }
        assertApproxEqAbs((totalAmount * 1) / 5, OwnerAmount, 1000);
    }
}
