// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/nft/DegenNFT.sol";
import "src/nft/NFTManager.sol";
import {INFTManagerDefination} from "src/interfaces/nft/INFTManager.sol";

contract NFTManagerReg is Test, IDegenNFTDefination {
    uint256 mainnetFork;
    DegenNFT degenNFT;
    NFTManager nftManager;

    function setUp() public {
        degenNFT = DegenNFT(0x060e571D900454c868E5D1D6e1a0c566A57224B0);
        nftManager = NFTManager(0x3955641fE1A2367be6Db951910ac05FFcdE14bDf);

        mainnetFork = vm.createFork(vm.envString("ETH_CHAIN_URL"));
        vm.rollFork(mainnetFork, 16_988_305);
        vm.selectFork(mainnetFork);
    }

    function testSimulateUpdateProperty() public {
        _upgradeTo();
        uint256[] memory tokenIds = new uint256[](5);
        tokenIds[0] = 341;
        tokenIds[1] = 348;
        tokenIds[2] = 914;
        tokenIds[3] = 927;
        tokenIds[4] = 1965;

        Property[] memory newProprties = new Property[](5);

        for (uint i = 0; i < tokenIds.length; i++) {
            Property memory property = degenNFT.getProperty(tokenIds[i]);
            assertEq(property.nameId, 32);
            assertEq(property.rarity, 4);
            assertEq(property.tokenType, 0);
            property.rarity = uint16(3);

            newProprties[i] = property;
        }

        // signer
        vm.startPrank(0xe3b0DF60032E05E0f08559f8F4962368ba47339B);
        nftManager.openMysteryBox(tokenIds, newProprties);

        for (uint i = 0; i < tokenIds.length; i++) {
            Property memory property = degenNFT.getProperty(tokenIds[i]);
            assertEq(property.nameId, 32);
            assertEq(property.rarity, 3);
            assertEq(property.tokenType, 0);
        }

        vm.stopPrank();
    }

    function _upgradeTo() internal {
        // owner
        vm.startPrank(0xf775Db913e735dDbB0E03c07665C78Bf2751399f);

        DegenNFT newDegenNFT = new DegenNFT();
        NFTManager newNFTManager = new NFTManager();

        degenNFT.upgradeTo(address(newDegenNFT));
        nftManager.upgradeTo(address(newNFTManager));
        vm.stopPrank();
    }
}
