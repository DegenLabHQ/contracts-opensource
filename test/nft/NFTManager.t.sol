// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/nft/NFTManager.sol";
import "murky/Merkle.sol";
import "src/mock/ChainlinkVRFProxyMock.sol";
import {INFTManager, INFTManagerDefination} from "src/interfaces/nft/INFTManager.sol";

contract NFTManagerTest is Test, INFTManagerDefination {
    NFTManager nftManager;
    ChainlinkVRFProxyMock chainlinkVRFProxyMock;
    address owner;
    address signer;

    function setUp() public {
        owner = vm.addr(1);
        signer = vm.addr(2);

        nftManager = new NFTManager();
        _initialize();
        _updateSigners();
        _setMintTime();
        _setMintFee();

        chainlinkVRFProxyMock = new ChainlinkVRFProxyMock();
        chainlinkVRFProxyMock.setController(address(nftManager));

        vm.prank(owner);
        nftManager.setBaseURI("https://www.baseuri.com/");
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

        assertEq(nftManager.balanceOf(address(12)), 1);
        assertEq(nftManager.ownerOf(1), address(12));
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

    function testAirdrop() public {
        address[] memory receivers = new address[](4);
        receivers[0] = address(10);
        receivers[1] = address(11);
        receivers[2] = address(12);
        receivers[3] = address(13);

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 2;
        quantities[1] = 3;
        quantities[2] = 1;
        quantities[3] = 4;

        uint256 totalFee;
        for (uint i = 0; i < quantities.length; i++) {
            totalFee += quantities[i] * 0.2 ether;
        }

        // only owner
        deal(address(3), 10 ether);
        vm.prank(address(3));
        vm.expectRevert("Ownable: caller is not the owner");
        nftManager.airdrop{value: totalFee}(receivers, quantities);

        // should pay enough mint fee fees
        deal(owner, 10 ether);
        vm.startPrank(owner);
        vm.expectRevert(MintFeeNotEnough.selector);
        nftManager.airdrop(receivers, quantities);

        // should success
        nftManager.airdrop{value: totalFee}(receivers, quantities);
        vm.stopPrank();

        assertEq(nftManager.balanceOf(address(10)), 2);
        assertEq(nftManager.balanceOf(address(11)), 3);
        assertEq(nftManager.ownerOf(2), address(10));
    }

    function testSetMetadatas() public {
        _setMetadataList();
    }

    // function testOpenMysteryBox() public {
    //     // set metadata list
    //     _setMetadataList();
    //     // set current as chainlink proxy
    //     vm.prank(owner);
    //     nftManager.setChainlinkVRFProxy(address(chainlinkVRFProxyMock));
    //     _airdrop();
    //     // request random number
    //     vm.prank(signer);
    //     uint256[] memory tokenIds = _generateTokenIds();
    //     nftManager.openMysteryBox(tokenIds);

    //     console.log(nftManager.tokenURI(1));
    // }

    function _initialize() internal {
        nftManager.initialize("TestNFT", "TNFT", owner);
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
        INFTManagerDefination.MintTime
            memory whitelistMintTime = INFTManagerDefination.MintTime({
                startTime: block.timestamp + 10,
                endTime: block.timestamp + 60 * 60
            });
        nftManager.setMintTime(
            INFTManagerDefination.MintType.WhitelistMint,
            whitelistMintTime
        );

        INFTManagerDefination.MintTime
            memory publicMintTime = INFTManagerDefination.MintTime({
                startTime: block.timestamp + 60,
                endTime: block.timestamp + 60 * 60
            });

        nftManager.setMintTime(
            INFTManagerDefination.MintType.PublicMint,
            publicMintTime
        );
        vm.stopPrank();
    }

    function _setMintFee() internal {
        vm.prank(owner);
        nftManager.setMintFee(0.2 ether);
    }

    function _setMetadataList() internal {
        INFTManager.Properties[]
            memory metadataList = new INFTManager.Properties[](4);
        metadataList[0] = INFTManagerDefination.Properties({
            name: "CZ",
            rarity: INFTManagerDefination.Rarity.Legendary,
            tokenType: INFTManagerDefination.TokenType.Shard
        });
        metadataList[0] = INFTManagerDefination.Properties({
            name: "CZ",
            rarity: INFTManagerDefination.Rarity.Legendary,
            tokenType: INFTManagerDefination.TokenType.Shard
        });
        metadataList[0] = INFTManagerDefination.Properties({
            name: "SBF",
            rarity: INFTManagerDefination.Rarity.Legendary,
            tokenType: INFTManagerDefination.TokenType.Shard
        });
        metadataList[0] = INFTManagerDefination.Properties({
            name: "SBF",
            rarity: INFTManagerDefination.Rarity.Legendary,
            tokenType: INFTManagerDefination.TokenType.Shard
        });

        vm.prank(owner);
        nftManager.setMetadatas(metadataList);
    }

    function _generateTokenIds() internal pure returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;
        tokenIds[3] = 4;
        return tokenIds;
    }
}
