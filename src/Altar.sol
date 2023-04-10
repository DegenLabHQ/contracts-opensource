// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {PortalLib} from "src/PortalLib.sol";
import {RebornPortalStorage} from "src/RebornPortalStorage.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {EIP712Upgradeable} from "src/oz/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSAUpgradeable} from "src/oz/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/**
 * @title Altar of heros
 */
abstract contract Altar is EIP712Upgradeable, RebornPortalStorage {
    function __Alter_init_unchained() internal onlyInitializing {
        __EIP712_init_unchained("Altar", "1");
    }

    function _useChar(CharParams calldata charparams) internal {
        if (charparams.charTokenId == 0) {
            return;
        }
        _comsumeAP(charparams.charTokenId);
        _checkChar(charparams);
    }

    function _comsumeAP(uint256 tokenId) internal {
        PortalLib._comsumeAP(tokenId, _characterProperties);
    }

    function _checkChar(CharParams calldata charparams) internal view {
        bytes32 structHash = keccak256(
            abi.encode(
                _CHARACTER_TYPEHASH,
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
        return _characterProperties[tokenId];
    }

    modifier onlySigner() {
        if (!signers[msg.sender]) {
            revert CommonError.NotSigner();
        }
        _;
    }
}
