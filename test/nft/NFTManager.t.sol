// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/nft/DegenNFT.sol";
import "src/nft/NFTManager.sol";
import "murky/Merkle.sol";
import {INFTManager, INFTManagerDefination} from "src/interfaces/nft/INFTManager.sol";
import {IDegenNFTDefination, IDegenNFT} from "src/interfaces/nft/IDegenNFT.sol";

contract NFTManagerTest is Test, INFTManagerDefination, IDegenNFTDefination {
    DegenNFT degenNFT;
    NFTManager nftManager;
    address owner;
    address signer;

    error CallerNotOwner();

    function setUp() public {
        owner = vm.addr(1);
        signer = vm.addr(2);

        degenNFT = new DegenNFT();
        nftManager = new NFTManager();
        _initialize();
        _updateSigners();
        _setMintTime();
        _setMintFee();

        vm.prank(owner);
        degenNFT.setBaseURI("https://www.baseuri.com/");
    }

    function testWhitelistMint() public {
        Merkle m = new Merkle();
        bytes32[] memory data = new bytes32[](4);
        data[0] = keccak256(bytes.concat(keccak256(abi.encode(address(10)))));
        data[1] = keccak256(bytes.concat(keccak256(abi.encode(address(11)))));
        data[2] = keccak256(bytes.concat(keccak256(abi.encode(address(12)))));
        data[3] = keccak256(bytes.concat(keccak256(abi.encode(address(13)))));

        // set merkle tree root
        bytes32 root = m.getRoot(data);
        vm.prank(owner);
        nftManager.setMerkleRoot(root);

        // mock mint
        bytes32[] memory proof = m.getProof(data, 2);
        vm.deal(address(12), 10 ether);
        vm.startPrank(address(12));
        vm.expectRevert(INFTManagerDefination.InvalidMintTime.selector);
        nftManager.whitelistMint{value: 0.2 ether}(proof);

        vm.warp(block.timestamp + 60);
        nftManager.whitelistMint{value: 0.2 ether}(proof);

        vm.stopPrank();

        assertEq(degenNFT.balanceOf(address(12)), 1);
        assertEq(degenNFT.ownerOf(1), address(12));
        console.log(degenNFT.tokenURI(1));
    }

    function testWhitelistMintMany() public {
        uint256 amount = 5000;
        bytes32[] memory data = new bytes32[](amount);

        for (uint256 i = 0; i < amount; i++) {
            address user = address(uint160(uint256(keccak256(abi.encode(i)))));
            data[i] = keccak256(bytes.concat(keccak256(abi.encode(user))));
        }
        vm.warp(block.timestamp + 60);
        Merkle m = new Merkle();
        // set merkle tree root
        bytes32 root = m.getRoot(data);
        vm.prank(owner);
        nftManager.setMerkleRoot(root);

        for (uint256 i = 0; i < amount; i++) {
            address user = address(uint160(uint256(keccak256(abi.encode(i)))));
            bytes32[] memory proof = m.getProof(data, i);

            if (degenNFT.totalMinted() >= nftManager.SUPPORT_MAX_MINT_COUNT()) {
                vm.expectRevert(
                    INFTManagerDefination.OutOfMaxMintCount.selector
                );
                hoax(user);
                nftManager.whitelistMint{value: 0.2 ether}(proof);
                break;
            }

            hoax(user);
            nftManager.whitelistMint{value: 0.2 ether}(proof);
        }
    }

    function testPublicMint() public {
        deal(address(11), 1 ether);

        vm.startPrank(address(11));
        vm.expectRevert(INFTManagerDefination.InvalidMintTime.selector);
        nftManager.publicMint{value: 0.4 ether}(2);

        vm.warp(block.timestamp + 70);
        vm.expectRevert(INFTManagerDefination.MintFeeNotEnough.selector);
        nftManager.publicMint{value: 0.2 ether}(2);

        vm.expectEmit(true, true, true, true);
        emit Minted(address(11), 2, 1);
        nftManager.publicMint{value: 0.4 ether}(2);
        vm.stopPrank();
    }

    function testSetBuckets() public {
        uint256[] memory buckets = new uint256[](3);
        buckets[0] = 0;
        buckets[1] = 1;
        buckets[2] = 2;

        uint256[] memory masks = new uint256[](3);
        masks[0] = uint256(1111111);
        masks[1] = uint256(2222222);
        masks[2] = uint256(3333333);

        vm.prank(owner);
        nftManager.setBuckets(buckets, masks);
    }

    function testOpenMysteryBox() public {
        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;
        tokenIds[3] = 4;

        IDegenNFTDefination.Property[]
            memory metadataList = new IDegenNFTDefination.Property[](4);
        metadataList[0] = IDegenNFTDefination.Property({
            nameId: 1001,
            rarity: 1,
            tokenType: 0
        });
        metadataList[1] = IDegenNFTDefination.Property({
            nameId: 1002,
            rarity: 2,
            tokenType: 0
        });
        metadataList[2] = IDegenNFTDefination.Property({
            nameId: 1003,
            rarity: 3,
            tokenType: 0
        });
        metadataList[3] = IDegenNFTDefination.Property({
            nameId: 1004,
            rarity: 4,
            tokenType: 0
        });

        vm.prank(owner);
        nftManager.openMysteryBox(tokenIds, metadataList);

        IDegenNFTDefination.Property memory t2Property = degenNFT.getProperty(
            2
        );
        IDegenNFTDefination.Property memory t3Property = degenNFT.getProperty(
            3
        );
        IDegenNFTDefination.Property memory t4Property = degenNFT.getProperty(
            4
        );
        assertEq(t2Property.nameId, 1002);
        assertEq(t2Property.rarity, 2);
        assertEq(t2Property.tokenType, 0);

        assertEq(t3Property.nameId, 1003);
        assertEq(t4Property.nameId, 1004);
    }

    function testPublicMintEdge() public {
        address user = address(11);
        deal(user, 10000 ether);
        uint256 amount = 2009;

        vm.warp(block.timestamp + 70);
        vm.prank(user);
        nftManager.publicMint{value: amount * 0.2 ether}(amount);

        vm.expectRevert(INFTManagerDefination.OutOfMaxMintCount.selector);
        nftManager.publicMint{value: 0.2 ether}(1);
    }

    function testPublicMintMany(uint256 amountSeed) public {
        address user = address(11);
        deal(user, 10000 ether);
        uint256 amount = bound(amountSeed, 1, 2009);

        vm.warp(block.timestamp + 70);
        vm.startPrank(user);
        nftManager.publicMint{value: amount * 0.2 ether}(amount);
        vm.stopPrank();

        assertEq(degenNFT.balanceOf(user), amount);
    }

    function testBatchMetadataUpdate() public {
        vm.expectEmit(true, true, true, true);
        emit BatchMetadataUpdate(0, type(uint256).max);
        vm.prank(degenNFT.owner());
        degenNFT.emitMetadataUpdate();
    }

    function testRoyltyInfo(
        address receiver,
        uint256 percentSeed,
        uint256 tokenId,
        uint256 priceSeed
    ) public {
        uint256 price = bound(priceSeed, 0, type(uint128).max);
        uint256 percent = bound(percentSeed, 0, degenNFT.PERCENTAGE_BASE());

        address r;
        uint256 a;
        (r, a) = degenNFT.royaltyInfo(tokenId, price);
        assertEq(r, address(0));
        assertEq(a, 0);

        vm.expectEmit(true, true, true, true);
        emit RoyaltyInfoSet(receiver, percent);

        vm.prank(degenNFT.owner());
        degenNFT.setRoyaltyInfo(receiver, uint96(percent));

        (r, a) = degenNFT.royaltyInfo(tokenId, price);

        assertEq(r, receiver);
        assertEq(a, (percent * price) / degenNFT.PERCENTAGE_BASE());
    }

    function _initialize() internal {
        degenNFT.initialize("Degen2009", "Degen2009", owner);
        nftManager.initialize(owner);

        vm.startPrank(owner);
        degenNFT.setManager(address(nftManager));
        nftManager.setDegenNFT(address(degenNFT));
        vm.stopPrank();
    }

    function _updateSigners() internal {
        vm.prank(owner);

        address[] memory toAdd = new address[](1);
        toAdd[0] = signer;

        address[] memory toRemove = new address[](0);

        nftManager.updateSigners(toAdd, toRemove);
    }

    function _setMintTime() internal {
        vm.startPrank(owner);
        INFTManagerDefination.StageTime
            memory whitelistMintTime = INFTManagerDefination.StageTime({
                startTime: block.timestamp + 10,
                endTime: block.timestamp + 60 * 60
            });
        nftManager.setMintTime(
            INFTManagerDefination.StageType.WhitelistMint,
            whitelistMintTime
        );

        INFTManagerDefination.StageTime
            memory publicMintTime = INFTManagerDefination.StageTime({
                startTime: block.timestamp + 60,
                endTime: block.timestamp + 60 * 60
            });

        nftManager.setMintTime(
            INFTManagerDefination.StageType.PublicMint,
            publicMintTime
        );
        vm.stopPrank();
    }

    function _setMintFee() internal {
        vm.prank(owner);
        nftManager.setMintFee(0.2 ether);
    }
}
