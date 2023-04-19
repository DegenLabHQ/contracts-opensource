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

    function testSimulateIncarnateWithCharCaseOne() public {
        portal = PortalMock(0x82724f06EA5cdeb574b84316c6d84A1362a41B61);
        vm.rollFork(29064337);
        vm.warp(0);
        mockUpgradeToDevVersion();

        InnateParams memory innateParams = InnateParams(
            0,
            0,
            31910000000000000,
            957300000000000000000000
        );
        SoupParams memory soupParams = SoupParams(
            40000000000000000,
            0,
            1681884053,
            0xd598bdaec980535d6a8dd8d027c4aaa9f1ce9fe66e5d7939959ee2500d4560de,
            0x2eea7c707ce5c157f3f74d5300a06b1d1bab9f06a1670727e8f0b770b8afc26e,
            28
        );

        PermitParams memory permitParams = PermitParams(
            115792089237316195423570985008687907853269984665640564039457584007913129639935,
            1681884116,
            0x890ae18d4fdf6dc2d3e77c96763166c7e4f86af775e6523d43e15b879d673711,
            0x2ab0629d012e09e6d000990383c8161b05b7a7e491d2c0d7a1bf70f1897a74cb,
            27
        );

        vm.expectEmit(true, true, true, true);

        emit Incarnate({
            user: 0x7F6be984a6EB10C7fC9F32bADb0062e8d951A497,
            charTokenId: 0,
            talentNativePrice: 0,
            talentRebornPrice: 0,
            propertyNativePrice: 31910000000000000,
            propertyRebornPrice: 957300000000000000000000,
            soupPrice: 40000000000000000
        });

        emit Deposit({
            season: 0,
            account: 0x7F6be984a6EB10C7fC9F32bADb0062e8d951A497,
            roundIndex: 1,
            amount: 4717296000000000,
            roundTotalAmount: 267129296000000000
        });

        emit PortalLib.ReferReward({
            user: 0x7F6be984a6EB10C7fC9F32bADb0062e8d951A497,
            ref1: 0x6eC33cecEa8B5E0423699A2866504FF3AF3CF53F,
            amount1: 12943800000000000,
            ref2: 0x0000000000000000000000000000000000000000,
            amount2: 0,
            rewardType: PortalLib.RewardType.NativeToken
        });

        vm.prank(0x7F6be984a6EB10C7fC9F32bADb0062e8d951A497);
        portal.incarnate{value: 0.072 ether}(
            innateParams,
            0x6eC33cecEa8B5E0423699A2866504FF3AF3CF53F,
            soupParams,
            permitParams
        );
    }
}
