// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import "./DegenERC721URIStorageUpgradeable.sol";
import "src/interfaces/nft/INFTManager.sol";
import "src/interfaces/nft/IDegenNFT.sol";
import "src/interfaces/nft/IChainlinkVRFProxy.sol";
import "./NFTManagerStorage.sol";

contract NFTManager is
    UUPSUpgradeable,
    SafeOwnableUpgradeable,
    INFTManager,
    NFTManagerStorage
{
    uint256 public constant SUPPORT_MAX_MINT_COUNT = 2009;
    using CountersUpgradeable for CountersUpgradeable.Counter;
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

        bool verified = checkWhiteList(merkleProof, msg.sender);

        if (!verified) {
            revert InvalidProof();
        }

        _mintTo(msg.sender, 1);
        hasMinted.set(uint160(msg.sender));
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

    function airdrop(
        address[] calldata receivers,
        uint256[] calldata quantities
    ) external payable override onlyOwner {
        if (receivers.length != quantities.length) {
            revert InvalidParams();
        }

        uint256 totalCount;
        for (uint256 i = 0; i < quantities.length; i++) {
            totalCount += quantities[i];
            if (quantities[i] == 0) {
                revert InvalidParams();
            }
        }

        if (msg.value < totalCount * mintFee) {
            revert MintFeeNotEnough();
        }

        if (degenNFT.totalMinted() + totalCount > SUPPORT_MAX_MINT_COUNT) {
            revert OutOfMaxMintCount();
        }

        for (uint256 i = 0; i < receivers.length; i++) {
            _mintTo(receivers[i], quantities[i]);
        }
    }

    function openMysteryBox(
        uint256[] calldata tokenIds
    ) external override onlySigner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (opened[tokenId]) {
                continue;
            }

            uint256 requestId = IChainlinkVRFProxy(chainlinkVRFProxy)
                .requestRandomWords(1, 30000);

            requestIdToTokenId[requestId] = tokenId;
        }
    }

    /**
     * @dev chainlink vrf proxy callback request randomWords
     * @param requestId requestId generage when request randomWords
     * @param randomWords return randomWords of requestId
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external onlyChainlinkVRFProxy {
        uint256 tokenId = requestIdToTokenId[requestId];
        if (tokenId == 0) {
            revert InvalidRequestId();
        }

        if (randomWords.length > 0) {
            _openMysteryBoxOf(tokenId, randomWords[0]);
        }
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
    function setMetadatas(
        IDegenNFTDefination.Property[] calldata metadataList
    ) external onlyOwner {
        for (uint256 i = 0; i < metadataList.length; i++) {
            metadatas[latestMetadataIdx] = metadataList[i];
            latestMetadataIdx++;
        }
    }

    // set chainlink vrf for open mystery box
    function setChainlinkVRFProxy(
        address chainlinkVRFProxy_
    ) external onlyOwner {
        if (address(chainlinkVRFProxy_) == address(0)) {
            revert ZeroAddressSet();
        }
        chainlinkVRFProxy = chainlinkVRFProxy_;

        emit ChangedChainlinkVRFProxy(chainlinkVRFProxy_);
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

    // get metadata config list
    function getMetadataList(
        uint16 length,
        uint256 offset
    ) external view returns (IDegenNFTDefination.Property[] memory) {
        IDegenNFTDefination.Property[]
            memory properties = new IDegenNFTDefination.Property[](length);
        for (uint256 i = offset; i < length; i++) {
            properties[i] = metadatas[i];
        }
        return properties;
    }

    function checkWhiteList(
        bytes32[] calldata merkleProof,
        address account
    ) public view returns (bool verified) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account))));
        verified = MerkleProofUpgradeable.verify(merkleProof, merkleRoot, leaf);
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

    function _checkOwner(address owner, uint256 tokenId) internal view {
        if (degenNFT.ownerOf(tokenId) != owner) {
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

    function _openMysteryBoxOf(uint256 tokenId, uint256 randomWord) internal {
        uint256 tempRandomWord = randomWord;
        uint256 randomMetadataId = tempRandomWord % SUPPORT_MAX_MINT_COUNT;
        bool metadataHasUsed = metadataUsed[randomMetadataId];
        while (metadataHasUsed && tempRandomWord > 0) {
            tempRandomWord = tempRandomWord / 1000;
            randomMetadataId = tempRandomWord % SUPPORT_MAX_MINT_COUNT;
            metadataHasUsed = metadataUsed[randomMetadataId];
        }

        if (metadataHasUsed) {
            // match tokenId and metadata failed
            _matchTokenIdAndMetadataFailed(tokenId);
        } else {
            // match tokenId and metadata success
            _matchTokenIdAndMetadataSuccess(tokenId, randomMetadataId);
        }
    }

    function _matchTokenIdAndMetadataFailed(uint256 tokenId) internal {
        emit OpenMysteryBoxFailed(tokenId);
    }

    function _matchTokenIdAndMetadataSuccess(
        uint256 tokenId,
        uint256 metadataId
    ) internal {
        IDegenNFTDefination.Property memory property = metadatas[metadataId];
        degenNFT.setProperties(tokenId, property);

        _setTokenURIOf(tokenId, metadataId);

        opened[tokenId] = true;
        metadataUsed[metadataId] = true;

        emit OpenMysteryBoxSuccess(tokenId, metadataId);
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

    modifier onlyChainlinkVRFProxy() {
        if (msg.sender != chainlinkVRFProxy) {
            revert OnlyChainlinkVRFProxy();
        }
        _;
    }

    modifier onlyMintTime(MintType mintType) {
        _checkMintTime(mintType);
        _;
    }

    /**********************************************
     * required functions
     **********************************************/
    receive() external payable {}
}
