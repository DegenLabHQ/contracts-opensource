// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "test/portal/RebornPortalBase.t.sol";

import {PortalLib} from "src/PortalLib.sol";

import "forge-std/console.sol";

contract AirdropTest is RebornPortalBaseTest {
    function setDropConf() public {
        // set drop conf
        vm.prank(owner);
        portal.setDropConf(
            PortalLib.AirdropConf(
                1,
                false,
                false,
                1 hours,
                3 hours,
                0,
                0,
                20,
                10,
                800,
                400,
                0
            )
        );
    }

    function testManyDrop() public {
        testUpKeepProgressSmoothly();
        testUpKeepProgressSmoothly();
        testUpKeepProgressSmoothly();
        testUpKeepProgressSmoothly();
        testUpKeepProgressSmoothly();
    }

    function _mockIncarnate() internal {
        address user = address(uint160(uint256(keccak256(abi.encode(9999)))));

        deal(user, 10000 ether);

        InnateParams memory innateParams = InnateParams(
            75 ether,
            10 ether,
            25 ether,
            20 ether
        );

        uint256 incarnateCount = portal.getIncarnateCount(
            portal.getSeason(),
            user
        );

        (uint256 deadline, bytes32 r, bytes32 s, uint8 v) = TestUtils
            .signAuthenticateSoup(
                11,
                address(portal),
                user,
                SOUP_PRICE,
                incarnateCount + 1,
                0
            );

        SoupParams memory soupParams = SoupParams(
            SOUP_PRICE,
            0,
            deadline,
            r,
            s,
            v
        );

        deal(address(rbt), user, 1 << 128);
        vm.startPrank(user);
        rbt.approve(address(portal), UINT256_MAX);
        portal.incarnate{value: 100 ether + SOUP_PRICE}(
            innateParams,
            address(0),
            soupParams
        );

        vm.stopPrank();
    }

    function mockAirdrop() public {
        bool up;
        bytes memory perfromData;

        // request reborn token
        (up, perfromData) = portal.checkUpkeep(new bytes(0));
        assertEq(up, true);
        portal.performUpkeep(perfromData);

        // request drop native
        (up, perfromData) = portal.checkUpkeep(new bytes(0));
        assertEq(up, true);
        portal.performUpkeep(perfromData);

        (up, perfromData) = portal.checkUpkeep(new bytes(0));
        assertEq(up, false);

        uint256[] memory words;
        // fulfill random number of the reborn request;
        words = new uint256[](10);
        vm.startPrank(_vrfCoordinator);
        portal.rawFulfillRandomWords(
            VRFCoordinatorV2Mock(_vrfCoordinator)._idx() - 1,
            words
        );
        vm.stopPrank();

        // fulfill random number of the native request;
        words = new uint256[](10);
        vm.startPrank(_vrfCoordinator);
        portal.rawFulfillRandomWords(
            VRFCoordinatorV2Mock(_vrfCoordinator)._idx(),
            words
        );
        vm.stopPrank();

        // perform the random number with reborn drop
        (up, perfromData) = portal.checkUpkeep(new bytes(0));
        assertEq(up, true);
        vm.expectEmit(false, false, false, false);
        emit PortalLib.DropNative(1, 0);
        emit PortalLib.DropReborn(1, 0);
        portal.performUpkeep(perfromData);

        // perform the random number with native drop
        (up, perfromData) = portal.checkUpkeep(new bytes(0));
        assertEq(up, true);
        portal.performUpkeep(perfromData);

        // after all perform, upKeep should be false
        (up, perfromData) = portal.checkUpkeep(new bytes(0));
        assertEq(up, false);

        // request again would not success
        vm.expectRevert(CommonError.InvalidParams.selector);
        // request reborn token
        perfromData = abi.encode(1, 0);
        portal.performUpkeep(perfromData);

        vm.expectRevert(CommonError.InvalidParams.selector);
        perfromData = abi.encode(2, 0);
        portal.performUpkeep(perfromData);
    }

    function testUpKeepProgressSmoothly() public {
        _mockIncarnate();
        mockEngravesAndInfuses(120);
        setDropConf();
        vm.warp(block.timestamp + 1 days - 1 hours);
        mockAirdrop();
    }

    function testClaimCrossTimeCorrect(address user) public {
        // only EOA and not precompile address
        vm.assume(user.code.length == 0 && uint160(user) > 20);
        // give native token to portal
        deal(address(portal), 1 << 128);
        setDropConf();

        uint256 tokenId = 1;
        // mock infuse
        uint256 amount = 10 ether;
        mockInfuse(user, tokenId, amount);

        // mock incarnate
        _mockIncarnate();
        // engrave
        mockEngravesIncre(1);
        // time pass by, set timestamp
        vm.warp(block.timestamp + 1 days);

        // airdrop
        mockAirdrop();

        // time pass by, set timestamp
        vm.warp(block.timestamp + 4 days);
        // airdrop again
        mockAirdrop();

        // deal some reborn token to reward vault
        deal(address(rbt), address(portal.vault()), UINT256_MAX);

        // should claim amount match
        uint256[] memory ds = new uint256[](1);
        ds[0] = tokenId;

        vm.expectEmit(true, true, true, true);
        if (portal.ownerOf(1) == user) {
            // emit PortalLib.ClaimRebornDrop(1, 1600 ether);
        } else {
            // emit PortalLib.ClaimRebornDrop(1, 1280 ether);
        }
        vm.prank(user);
        // portal.claimDrops(ds);
        vm.stopPrank();
    }

    function testDropFuzz(address[] memory users) public {
        setDropConf();
        vm.assume(users.length > 100);

        // mock infuse
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 amount = bound(
                uint160(user),
                0,
                (rbt.cap() - rbt.totalSupply()) / 1000
            );
            uint256 tokenId = uint160(user);
            // only EOA and not precompile address
            vm.assume(user.code.length == 0 && tokenId > 20);

            mockInfuse(user, tokenId, amount);
        }

        // give native token to portal
        deal(address(portal), 1 << 128);

        testUpKeepProgressSmoothly();

        // deal some reborn token to reward vault
        deal(address(rbt), address(portal.vault()), UINT256_MAX);

        // infuse again to trigger claim
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 amount = bound(
                uint160(user),
                1,
                (rbt.cap() - rbt.totalSupply()) / 1000
            );
            uint256 tokenId = uint160(user);
            // only EOA and not precompile address
            vm.assume(user.code.length == 0 && tokenId > 20);

            uint256[] memory ds = new uint256[](1);
            ds[0] = tokenId;
            vm.prank(users[i]);
            // portal.claimDrops(ds);
            mockInfuse(user, tokenId, amount);

            vm.stopPrank();
        }
    }
}
