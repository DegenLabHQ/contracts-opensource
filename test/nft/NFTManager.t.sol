// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/nft/DegenNFT.sol";
import "src/nft/NFTManager.sol";
import "murky/Merkle.sol";
import "src/mock/ChainlinkVRFProxyMock.sol";
import {INFTManager, INFTManagerDefination} from "src/interfaces/nft/INFTManager.sol";
import {IDegenNFTDefination, IDegenNFT} from "src/interfaces/nft/IDegenNFT.sol";

contract NFTManagerTest is Test, INFTManagerDefination {
    DegenNFT degenNFT;
    NFTManager nftManager;
    ChainlinkVRFProxyMock chainlinkVRFProxyMock;
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

        chainlinkVRFProxyMock = new ChainlinkVRFProxyMock();
        chainlinkVRFProxyMock.setController(address(nftManager));

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

    function testOpenMysteryBox() public {
        _openMysteryBox();
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

    function _openMysteryBox() internal {
        IDegenNFTDefination.Property[]
            memory metadataList = new IDegenNFTDefination.Property[](4);
        metadataList[0] = IDegenNFTDefination.Property({
            nameId: 1001,
            rarity: 1,
            tokenType: 0
        });
        metadataList[1] = IDegenNFTDefination.Property({
            nameId: 1001,
            rarity: 1,
            tokenType: 0
        });
        metadataList[2] = IDegenNFTDefination.Property({
            nameId: 1001,
            rarity: 2,
            tokenType: 0
        });
        metadataList[3] = IDegenNFTDefination.Property({
            nameId: 1001,
            rarity: 2,
            tokenType: 0
        });

        vm.prank(owner);
        nftManager.openMysteryBox(metadataList);
    }

    // function _generateTokenIds() internal pure returns (uint256[] memory) {
    //     uint256[] memory tokenIds = new uint256[](4);
    //     tokenIds[0] = 1;
    //     tokenIds[1] = 2;
    //     tokenIds[2] = 3;
    //     tokenIds[3] = 4;
    //     return tokenIds;
    // }
}
