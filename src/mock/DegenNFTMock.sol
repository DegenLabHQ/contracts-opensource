// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract DegenNFTMock {
    struct Metadata {
        uint256 tokenId;
        uint16 nameId;
        uint16 rarity;
        uint16 tokenType;
    }

    function generateMask(
        Metadata[] memory metadataList
    ) external pure returns (uint256) {
        uint256 mask;
        for (uint i = 0; i < metadataList.length; i++) {
            Metadata memory metadata = metadataList[i];
            uint16 property = encodeProperty(
                metadata.nameId,
                metadata.rarity,
                metadata.tokenType
            );

            mask |= uint256(property) << (((metadata.tokenId - 1) % 16) * 16);
        }
        return mask;
    }

    function encodeProperty(
        // Property memory property_
        uint16 nameId,
        uint16 rarity,
        uint16 tokenType
    ) public pure returns (uint16 property) {
        property = (property << 12) | nameId;
        property = (property << 3) | rarity;
        property = (property << 1) | tokenType;
    }

    function decodeProperty(
        uint16 property
    ) public pure returns (uint16 nameId, uint16 rarity, uint16 tokenType) {
        nameId = (property >> 4) & 0x0fff;
        rarity = (property >> 1) & 0x07;
        tokenType = property & 0x01;
    }
}
