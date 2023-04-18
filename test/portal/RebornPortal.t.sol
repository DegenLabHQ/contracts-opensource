// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "test/portal/RebornPortalBase.t.sol";

contract RebornPortalCommonTest is RebornPortalBaseTest {
    function testIncarnateWithoutChar() public {
        InnateParams memory innateParams = InnateParams(
            0.1 ether,
            10 ether,
            0.2 ether,
            20 ether
        );

        SoupParams memory soupParams = SoupParams(
            0.1 ether,
            0,
            block.timestamp + 100,
            bytes32(0),
            bytes32(0),
            uint8(0)
        );

        vm.expectRevert(InsufficientAmount.selector);

        hoax(_user);
        portal.incarnate{value: 0.1 ether}(
            innateParams,
            address(0),
            soupParams
        );

        deal(address(rbt), _user, 1 << 128);

        vm.expectEmit(true, true, true, true);
        emit Incarnate(
            _user,
            0,
            0.1 ether,
            10 ether,
            0.2 ether,
            20 ether,
            SOUP_PRICE
        );

        vm.startPrank(_user);
        rbt.approve(address(portal), UINT256_MAX);
        portal.incarnate{value: 0.3 ether + SOUP_PRICE}(
            innateParams,
            address(0),
            soupParams
        );
        vm.stopPrank();
    }

    function testIncarnateWithChar(uint256 tokenId) public {
        InnateParams memory innateParams = InnateParams(
            0.1 ether,
            10 ether,
            0.2 ether,
            20 ether
        );

        // set default property
        mockSetOneTokenIdDefaultProperty(tokenId);
        // time pass by to restore AP
        vm.warp(block.timestamp + 86400);

        (
            uint256 deadline,
            bytes32 r,
            bytes32 s,
            uint8 v
        ) = mockSignCharOwnership(_user, SOUP_PRICE, 1, tokenId);

        SoupParams memory soupParams = SoupParams(
            SOUP_PRICE,
            tokenId,
            deadline,
            r,
            s,
            v
        );

        vm.expectRevert(InsufficientAmount.selector);

        hoax(_user);
        portal.incarnate{value: 0.1 ether}(
            innateParams,
            address(0),
            soupParams
        );

        deal(address(rbt), _user, 1 << 128);

        vm.expectEmit(true, true, true, true);
        emit Incarnate(
            _user,
            tokenId,
            0.1 ether,
            10 ether,
            0.2 ether,
            20 ether,
            SOUP_PRICE
        );

        vm.startPrank(_user);
        rbt.approve(address(portal), UINT256_MAX);
        portal.incarnate{value: 0.3 ether + SOUP_PRICE}(
            innateParams,
            address(0),
            soupParams
        );
        vm.stopPrank();
    }

    function testEngrave(
        bytes32 seed,
        uint256 reward,
        uint256 score,
        uint256 age
    ) public {
        vm.assume(reward < rbt.cap() - 100 ether);
        deal(address(rbt), address(portal.vault()), reward);

        // testIncarnateWithPermit();
        testIncarnateWithoutChar();
        vm.expectEmit(true, true, true, true);
        emit Engrave(seed, _user, 1, score, reward);

        vm.prank(_signer);
        portal.engrave(seed, _user, reward, score, age, 1, "@ElonMusk");
    }

    // for test engrave gas
    function testManyEngravesIncre() public {
        mockEngravesIncre(500);
    }

    // for test engrave gas
    function testManyEngravesDecre() public {
        mockEngravesDecre(500);
    }

    function testInfuseNumericalValue(uint256 amount) public {
        vm.assume(amount < (rbt.cap() - 100 ether) / 2);
        vm.assume(amount > 0);

        vm.expectEmit(true, true, true, true);
        emit Infuse(_user, 1, amount, TributeDirection.Forward);
        emit Transfer(_user, address(portal), amount);

        mockInfuse(_user, 1, amount);

        assertEq(portal.getPool(1).totalAmount, amount);
        assertEq(portal.getPortfolio(_user, 1).accumulativeAmount, amount);
    }

    function testBurnPool(uint256 amount) public {
        vm.assume(amount < rbt.cap() / 2);

        testInfuseNumericalValue(amount);
        assertEq(
            IERC20Upgradeable(address(rbt)).balanceOf(address(burnPool)),
            amount
        );

        vm.prank(owner);
        portal.burnFromBurnPool(amount);
        assertEq(
            IERC20Upgradeable(address(rbt)).balanceOf(address(burnPool)),
            0
        );
    }

    function testInfuseWithPermit() public {
        uint256 amount = 1 ether;
        testEngrave(bytes32(new bytes(32)), 10, 10, 10);

        deal(address(rbt), _user, amount);

        (
            uint256 permitAmount,
            uint256 deadline,
            bytes32 r,
            bytes32 s,
            uint8 v
        ) = TestUtils.permitRBT(10, rbt, address(portal));
        // 10 is _user's private key

        vm.prank(_user);
        portal.infuse(
            1,
            amount,
            TributeDirection.Forward,
            permitAmount,
            deadline,
            r,
            s,
            v
        );
    }

    function testSwitchPool() public {
        deal(address(rbt), address(portal.vault()), 2 * 1 ether);

        vm.startPrank(_signer);
        portal.engrave(bytes32("0x1"), _user, 100, 10, 10, 10, "vitalik.eth");
        portal.engrave(
            bytes32("0x2"),
            _user,
            100,
            10,
            10,
            10,
            "cyberconnect.cc"
        );
        vm.stopPrank();

        // infuse pool 1
        mockInfuse(_user, 1, 0.5 * 1 ether);
        assertEq(portal.getPool(1).totalAmount, 0.5 * 1 ether);
        assertEq(
            portal.getPortfolio(_user, 1).accumulativeAmount,
            0.5 * 1 ether
        );

        // infuse pool 2
        mockInfuse(_user, 2, 1 ether);
        assertEq(portal.getPool(2).totalAmount, 1 ether);
        assertEq(portal.getPortfolio(_user, 2).accumulativeAmount, 1 ether);

        // switch pool 1 -> pool 2
        vm.prank(_user);
        portal.switchPool(1, 2, 0.1 * 1 ether, TributeDirection.Forward);
        assertEq(portal.getPool(1).totalAmount, 0.4 * 1 ether);
        assertEq(
            portal.getPortfolio(_user, 1).accumulativeAmount,
            0.4 * 1 ether
        );
        assertEq(portal.getPool(2).totalAmount, 1.095 * 1 ether);
        assertEq(
            portal.getPortfolio(_user, 2).accumulativeAmount,
            1.095 * 1 ether
        );

        vm.expectRevert();
        vm.prank(_user);
        portal.switchPool(1, 2, 0.5 * 1 ether, TributeDirection.Forward);
    }

    function testCoinday() public {
        testEngrave(bytes32(new bytes(32)), 10, 10, 10);
        address user1 = address(20);
        address user2 = address(21);
        address user3 = address(23);

        mockInfuse(user1, 1, 10 ether);
        vm.warp(block.timestamp + 1 days);

        mockInfuse(user1, 1, 1 ether);
        mockInfuse(user2, 1, 10 ether);
        vm.warp(block.timestamp + 1 days);

        mockInfuse(user3, 1, 3 ether);
        vm.warp(block.timestamp + 2 days);
        uint256 poolCoinday;
        uint256 user1Coinday;
        uint256 user2Coinday;
        uint256 user3Coinday;
        (user1Coinday, poolCoinday) = portal.getCoinday(1, user1);
        (user2Coinday, poolCoinday) = portal.getCoinday(1, user2);
        (user3Coinday, poolCoinday) = portal.getCoinday(1, user3);
        assertEq(user1Coinday, 43 ether);
        assertEq(user2Coinday, 30 ether);
        assertEq(user3Coinday, 6 ether);
        assertEq(poolCoinday, 79 ether);
    }

    function testTokenUri(
        bytes32 seed,
        uint208 reward,
        uint16 score,
        uint16 age
    ) public {
        testEngrave(seed, reward, score, age);
        string memory metadata = portal.tokenURI(1);
        console.log(metadata);
    }

    function testBaptise(address user, uint256 amount) public {
        vm.assume(user != address(0));
        vm.assume(amount < rbt.cap() - rbt.totalSupply());
        deal(address(rbt), address(portal.vault()), amount);

        vm.expectEmit(true, true, true, true);
        emit Baptise(user, amount, BaptiseType.TwitterShare);
        emit Transfer(address(0), user, amount);

        vm.prank(_signer);
        portal.baptise(user, amount, BaptiseType.TwitterShare);
    }

    function testSeedRead(
        bytes32 seed,
        uint208 reward,
        uint16 score,
        uint16 age
    ) public {
        vm.assume(uint256(seed) > 1);
        testEngrave(seed, reward, score, age);

        assertEq(portal.seedExists(seed), true);
        assertEq(portal.seedExists(bytes32(uint256(seed) - 1)), false);
    }

    function testRewardReferrers() public {
        address ref1 = vm.addr(20);
        address ref2 = vm.addr(21);

        vm.prank(owner);
        portal.setReferrerRewardFee(800, 200, PortalLib.RewardType.NativeToken);

        // refer ref2->ref1
        hoax(ref1);
        incarnateWithReferrer(
            ref1,
            ref2,
            0.61 * 0.08 * 1e18,
            address(0),
            0,
            0.61 ether
        );

        // refer ref1->user
        vm.deal(ref1, 0);
        vm.deal(ref2, 0);
        hoax(_user);
        incarnateWithReferrer(
            _user,
            ref1,
            0.61 * 0.08 * 1e18,
            ref2,
            0.61 * 0.02 * 1e18,
            0.61 * 1 ether
        );
    }

    function incarnateWithReferrer(
        address account,
        address ref1,
        uint256 ref1Reward,
        address ref2,
        uint256 ref2Reward,
        uint256 amount
    ) public {
        vm.expectEmit(true, true, true, true);
        emit PortalLib.ReferReward(
            account,
            ref1,
            ref1Reward,
            ref2,
            ref2Reward,
            PortalLib.RewardType.NativeToken
        );
        payable(address(portal)).call{value: amount}(
            abi.encodeWithSignature(
                "incarnate((uint256,uint256),address,uint256)",
                0.1 ether,
                0.5 ether,
                ref1,
                SOUP_PRICE
            )
        );

        assertEq(ref1.balance, ref1Reward);
        assertEq(ref2.balance, ref2Reward);
    }

    function mockIncarnate() public {
        uint256 amount = 1 ether;
        deal(_user, amount);
        vm.prank(_user);
        payable(address(portal)).call{value: amount}(
            abi.encodeWithSignature(
                "incarnate((uint256,uint256),address,uint256)",
                0.1 ether,
                0.5 ether,
                address(1),
                SOUP_PRICE
            )
        );
    }

    function testIncarnateLimitZero() public {
        vm.prank(portal.owner());
        portal.setIncarnationLimit(0);

        vm.expectRevert(IRebornDefination.IncarnationExceedLimit.selector);
        mockIncarnate();
    }

    function testIncarnateLimitOne() public {
        vm.prank(portal.owner());
        vm.expectEmit(true, true, true, true);
        emit NewIncarnationLimit(0);

        portal.setIncarnationLimit(0);

        vm.expectRevert(IRebornDefination.IncarnationExceedLimit.selector);
        mockIncarnate();
    }

    function testIncarnateLimitMany(uint256 nSeed) public {
        uint256 n = bound(nSeed, 1, 1024);
        vm.expectEmit(true, true, true, true);
        emit NewIncarnationLimit(n);

        vm.prank(portal.owner());
        portal.setIncarnationLimit(n);

        for (uint256 i = 0; i < n - 1; i++) {
            mockIncarnate();
        }

        vm.expectRevert(IRebornDefination.IncarnationExceedLimit.selector);
        mockIncarnate();
    }

    function testStopBeta() public {
        uint256 stopBetaBlockNumber = 26623000;

        vm.prank(owner);
        portal.setBetaStopedBlockNumber(stopBetaBlockNumber);

        vm.roll(26623001);
        vm.expectRevert(BetaStoped.selector);
        mockIncarnate();

        // mockInfuse
        deal(address(rbt), _user, 1 ether);
        vm.startPrank(_user);
        rbt.approve(address(portal), 1 ether);
        vm.expectRevert(BetaStoped.selector);
        portal.infuse(1, 1 ether, TributeDirection.Forward);
        vm.stopPrank();
    }
}
