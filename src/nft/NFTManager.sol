// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {INFTManager} from "src/interfaces/nft/INFTManager.sol";
import {IDegenNFTDefination} from "src/interfaces/nft/IDegenNFT.sol";
import {NFTManagerStorage} from "src/nft/NFTManagerStorage.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {DegenNFT} from "src/nft/DegenNFT.sol";

contract NFTManager is
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    INFTManager,
    NFTManagerStorage,
    PausableUpgradeable
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
        __Pausable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function whitelistMint(
        bytes32[] calldata merkleProof
    )
        public
        payable
        override
        whenNotPaused
        onlyStageTime(StageType.WhitelistMint)
    {
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
    )
        public
        payable
        override
        whenNotPaused
        onlyStageTime(StageType.PublicMint)
    {
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

    function merge(
        uint256 tokenId1,
        uint256 tokenId2
    ) external override onlyStageTime(StageType.Merge) whenNotPaused {
        _checkOwner(msg.sender, tokenId1);
        _checkOwner(msg.sender, tokenId2);

        bool propertiEq = checkPropertiesEq(tokenId1, tokenId2);
        if (!propertiEq) {
            revert InvalidTokens();
        }

        degenNFT.burn(tokenId1);
        degenNFT.burn(tokenId2);

        uint256 tokenId = degenNFT.nextTokenId();

        _mintTo(msg.sender, 1);

        emit MergeTokens(msg.sender, tokenId1, tokenId2, tokenId);
    }

    /**
     * @dev set id=>metadata map
     */
    function openMysteryBox(
        uint256[] calldata tokenIds,
        IDegenNFTDefination.Property[] calldata metadataList
    ) external onlyOwner {
        if (tokenIds.length != metadataList.length) {
            revert InvalidParams();
        }
        for (uint256 i = 0; i < metadataList.length; i++) {
            degenNFT.setProperties(tokenIds[i], metadataList[i]);
        }
    }

    function setBuckets(
        uint256[] calldata buckets,
        uint256[] calldata masks
    ) external onlyOwner {
        if (buckets.length != masks.length) {
            revert InvalidParams();
        }

        for (uint i = 0; i < buckets.length; i++) {
            degenNFT.setBucket(buckets[i], masks[i]);

            emit SetBucket(buckets[i], masks[i]);
        }
    }

    function burn(uint256 tokenId) external override whenNotPaused {
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
            refundConfig.degenToken
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

    function setMintFee(uint256 mintFee_) external onlyOwner {
        mintFee = mintFee_;

        emit MintFeeSet(mintFee);
    }

    function setDegenNFT(address degenNFT_) external onlyOwner {
        if (degenNFT_ == address(0)) {
            revert ZeroAddressSet();
        }
        degenNFT = DegenNFT(degenNFT_);
        emit SetDegenNFT(degenNFT_);
    }

    function setMintTime(
        StageType mintType_,
        StageTime calldata mintTime_
    ) external onlyOwner {
        if (mintTime_.startTime >= mintTime_.endTime) {
            revert InvalidParams();
        }

        stageTime[mintType_] = mintTime_;

        emit SetMintTime(mintType_, mintTime_);
    }

    function setBurnRefundConfig(
        uint256[] calldata levels,
        BurnRefundConfig[] calldata configs
    ) external override onlyOwner {
        // burnRefundConfigs = configs;
        for (uint256 i = 0; i < configs.length; i++) {
            uint256 level = levels[i];
            BurnRefundConfig memory config = configs[i];
            burnRefundConfigs[level] = config;
            emit SetBurnRefundConfig(level, config);
        }
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    /**********************************************
     * read functions
     **********************************************/

    function checkWhiteList(
        bytes32[] calldata merkleProof,
        address account
    ) public view returns (bool valid) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account))));
        valid = MerkleProofUpgradeable.verify(merkleProof, merkleRoot, leaf);
    }

    function getBurnRefundConfigs(
        uint256 level
    ) public view returns (BurnRefundConfig memory) {
        return burnRefundConfigs[level];
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

    function _checkStageTime(StageType stageType) internal view {
        if (
            block.timestamp < stageTime[stageType].startTime ||
            block.timestamp > stageTime[stageType].endTime
        ) {
            revert InvalidMintTime();
        }
    }

    // only name && tokenType equal means token1 and token2 can merge
    function checkPropertiesEq(
        uint256 tokenId1,
        uint256 tokenId2
    ) public view returns (bool) {
        IDegenNFTDefination.Property memory token1Property = degenNFT
            .getProperty(tokenId1);
        IDegenNFTDefination.Property memory token2Property = degenNFT
            .getProperty(tokenId2);

        return
            token1Property.nameId == token2Property.nameId &&
            token1Property.tokenType == token2Property.tokenType;
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

    modifier onlyStageTime(StageType stageType) {
        _checkStageTime(stageType);
        _;
    }
}