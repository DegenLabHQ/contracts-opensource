// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {PortalLib} from "src/PortalLib.sol";
import {RebornPortalStorage} from "src/RebornPortalStorage.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {EIP712Upgradeable} from "src/oz/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSAUpgradeable} from "src/oz/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {AccessBase} from "src/base/AccessBase.sol";

/**
 * @title Altar of heros
 */
abstract contract Altar is EIP712Upgradeable, RebornPortalStorage, AccessBase {
    function __Altar_init_unchained() internal onlyInitializing {
        __EIP712_init_unchained("Altar", "1");
    }

    function _useChar(CharParams calldata charparams) internal {
        if (charparams.charTokenId == 0) {
            return;
        }
        _checkChar(charparams);
        PortalLib._comsumeAP(charparams.charTokenId, _characterProperties);
    }

    function _checkChar(CharParams calldata charparams) internal view {
        if (block.timestamp >= charparams.deadline) {
            revert CommonError.SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PortalLib._CHARACTER_TYPEHASH,
                msg.sender,
                charparams.charTokenId,
                charparams.deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(
            hash,
            charparams.v,
            charparams.r,
            charparams.s
        );
        if (!signers[signer]) {
            revert CommonError.NotSigner();
        }
    }

    function setCharProperty(
        uint256[] calldata tokenIds,
        PortalLib.CharacterParams[] calldata charParams
    ) external onlySigner {
        PortalLib.setCharProperty(tokenIds, charParams, _characterProperties);
    }

    function readCharProperty(
        uint256 tokenId
    ) public view returns (PortalLib.CharacterProperty memory) {
        PortalLib.CharacterProperty memory charProperty = _characterProperties[
            tokenId
        ];

        charProperty.currentAP = uint8(
            PortalLib._calculateCurrentAP(charProperty)
        );

        return charProperty;
    }
}
