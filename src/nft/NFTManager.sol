// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import {DegenERC721URIStorageUpgradeable} from "src/nft/DegenERC721URIStorageUpgradeable.sol";
import {INFTManager} from "src/interfaces/nft/INFTManager.sol";
import {IDegenNFT, IDegenNFTDefination} from "src/interfaces/nft/IDegenNFT.sol";
import {NFTManagerStorage} from "src/nft/NFTManagerStorage.sol";

contract NFTManager is
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    INFTManager,
    NFTManagerStorage
{
    uint256 public constant SUPPORT_MAX_MINT_COUNT = 2009;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    /**********************************************
     * write functions
     **********************************************/
    function initialize(address owner_) public initializer {
        if (owner_ == address(0)) {
            revert ZeroOwnerSet();
        }

        __Ownable_init(owner_);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function whitelistMint(
        bytes32[] calldata merkleProof
    ) public payable override onlyMintTime(MintType.WhitelistMint) {
        if (hasMinted.get(uint160(msg.sender))) {
            revert AlreadyMinted();
        }

        if (degenNFT.totalMinted() >= SUPPORT_MAX_MINT_COUNT) {
            revert OutOfMaxMintCount();
        }

        if (msg.value < mintFee) {
            revert MintFeeNotEnough();
        }

        bool valid = checkWhiteList(merkleProof, msg.sender);

        if (!valid) {
            revert InvalidProof();
        }

        hasMinted.set(uint160(msg.sender));
        _mintTo(msg.sender, 1);
    }

    function publicMint(
        uint256 quantity
    ) public payable override onlyMintTime(MintType.PublicMint) {
        if (degenNFT.totalMinted() + quantity > SUPPORT_MAX_MINT_COUNT) {
            revert OutOfMaxMintCount();
        }

        if (quantity == 0) {
            revert InvalidParams();
        }

        if (msg.value < mintFee * quantity) {
            revert MintFeeNotEnough();
        }

        _mintTo(msg.sender, quantity);
    }

    function merge(uint256 tokenId1, uint256 tokenId2) external override {
        _checkOwner(msg.sender, tokenId1);
        _checkOwner(msg.sender, tokenId2);

        bool propertiEq = _checkPropertiesEq(tokenId1, tokenId2);
        if (!propertiEq) {
            revert InvalidTokens();
        }

        degenNFT.burn(tokenId1);
        degenNFT.burn(tokenId2);

        uint256 tokenId = degenNFT.nextTokenId();

        _mintTo(msg.sender, 1);
        _setTokenURIOf(tokenId, tokenId);

        emit MergeTokens(msg.sender, tokenId1, tokenId2, tokenId);
    }

    function burn(uint256 tokenId) external override {
        if (!degenNFT.exists(tokenId)) {
            revert TokenIdNotExsis();
        }

        uint256 level = degenNFT.getLevel(tokenId);
        if (level == 0) {
            revert LevelZeroCannotBurn();
        }

        _checkOwner(msg.sender, tokenId);

        degenNFT.burn(tokenId);

        // refund fees
        BurnRefundConfig memory refundConfig = burnRefundConfigs[
            degenNFT.getLevel(tokenId)
        ];

        // refund NativeToken
        if (refundConfig.nativeToken > 0) {
            payable(msg.sender).transfer(refundConfig.nativeToken);
        }

        emit BurnToken(
            msg.sender,
            tokenId,
            refundConfig.nativeToken,
            refundConfig.rebornToken
        );
    }

    function updateSigners(
        address[] calldata toAdd,
        address[] calldata toRemove
    ) external onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], true);
        }

        for (uint256 i = 0; i < toRemove.length; i++) {
            signers[toRemove[i]] = false;
            emit SignerUpdate(toRemove[i], false);
        }
    }

    // set white list merkler tree root
    function setMerkleRoot(bytes32 root) external override onlyOwner {
        if (root == bytes32(0)) {
            revert ZeroRootSet();
        }

        merkleRoot = root;

        emit MerkleTreeRootSet(root);
    }

    /**
     * @dev set id=>metadata map
     * latestMetadata is useed for compatible sence with multiple times to setting
     */
    function openMysteryBox(
        IDegenNFTDefination.Property[] calldata metadataList
    ) external onlyOwner {
        for (uint256 i = 0; i < metadataList.length; i++) {
            degenNFT.setProperties(latestMetadataIdx, metadataList[i]);
            latestMetadataIdx++;
        }
    }

    function setMintFee(uint256 mintFee_) external onlyOwner {
        mintFee = mintFee_;

        emit MintFeeSet(mintFee);
    }

    function setDegenNFT(address degenNFT_) external onlyOwner {
        if (degenNFT_ == address(0)) {
            revert ZeroAddressSet();
        }
        degenNFT = IDegenNFT(degenNFT_);
        emit SetDegenNFT(degenNFT_);
    }

    function setMintTime(
        MintType mintType_,
        MintTime calldata mintTime_
    ) external onlyOwner {
        if (mintTime_.startTime >= mintTime_.endTime) {
            revert InvalidParams();
        }

        mintTime[mintType_] = mintTime_;

        emit SetMintTime(mintType_, mintTime_);
    }

    function setBurnRefundConfig(
        BurnRefundConfig[] calldata configs
    ) external onlyOwner {
        delete burnRefundConfigs;

        // burnRefundConfigs = configs;
        for (uint256 i = 0; i < configs.length; i++) {
            burnRefundConfigs[i] = configs[i];
        }
        emit SetBurnRefundConfig(burnRefundConfigs);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    /**********************************************
     * read functions
     **********************************************/
    function exists(uint256 tokenId) external view returns (bool) {
        return degenNFT.exists(tokenId);
    }

    function checkWhiteList(
        bytes32[] calldata merkleProof,
        address account
    ) public view returns (bool valid) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account))));
        valid = MerkleProofUpgradeable.verify(merkleProof, merkleRoot, leaf);
    }

    function propertyOf(
        uint256 tokenId
    ) public view returns (IDegenNFTDefination.Property memory) {
        return degenNFT.getProperty(tokenId);
    }

    function getBurnRefundConfigs()
        public
        view
        returns (BurnRefundConfig[] memory)
    {
        return burnRefundConfigs;
    }

    function minted(address account) external view returns (bool) {
        return hasMinted.get(uint160(account));
    }

    /**********************************************
     * internal functions
     **********************************************/
    function _mintTo(address to, uint256 quantity) internal {
        uint256 startTokenId = degenNFT.nextTokenId();
        degenNFT.mint(to, quantity);

        emit Minted(msg.sender, quantity, startTokenId);
    }

    function _checkOwner(address owner_, uint256 tokenId) internal view {
        if (degenNFT.ownerOf(tokenId) != owner_) {
            revert NotTokenOwner();
        }
    }

    function _checkMintTime(MintType mintType) internal view {
        if (
            block.timestamp < mintTime[mintType].startTime ||
            block.timestamp > mintTime[mintType].endTime
        ) {
            revert InvalidMintTime();
        }
    }

    // only name && tokenType equal means token1 and token2 can merge
    function _checkPropertiesEq(
        uint256 tokenId1,
        uint256 tokenId2
    ) internal view returns (bool) {
        IDegenNFTDefination.Property memory token1Property = degenNFT
            .getProperty(tokenId1);
        IDegenNFTDefination.Property memory token2Property = degenNFT
            .getProperty(tokenId2);

        return
            token1Property.nameId == token2Property.nameId &&
            token1Property.tokenType == token2Property.tokenType;
    }

    function _setTokenURIOf(uint256 tokenId, uint256 metadataId) internal {
        degenNFT.setTokenURI(
            tokenId,
            string.concat(StringsUpgradeable.toString(metadataId), ".json")
        );
    }

    /**********************************************
     * modiriers
     **********************************************/
    modifier onlySigner() {
        if (!signers[msg.sender]) {
            revert NotSigner();
        }
        _;
    }

    modifier onlyMintTime(MintType mintType) {
        _checkMintTime(mintType);
        _;
    }
}
