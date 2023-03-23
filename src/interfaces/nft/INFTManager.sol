// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface INFTManagerDefination {
    enum MintType {
        WhitelistMint,
        PublicMint
    }

    enum Rarity {
        Legendary,
        Epic,
        Rare,
        Uncommon,
        Common
    }

    enum TokenType {
        Standard,
        Shard
    }

    struct MintTime {
        uint256 startTime;
        uint256 endTime; // mint end time,if no need set 4294967295(2106-02-07 14:28:15)
    }

    struct Properties {
        string name;
        Rarity rarity;
        TokenType tokenType;
    }

    struct BurnRefundConfig {
        uint256 nativeToken;
        uint256 RebornToken;
    }

    /**********************************************
     * errors
     **********************************************/
    error ZeroOwnerSet();
    error NotSigner();
    error OutOfMaxMintCount();
    error AlreadyMinted();
    error ZeroRootSet();
    error InvalidProof();
    error NotTokenOwner();
    error InvalidTokens();
    error ZeroAddressSet();
    error OnlyChainlinkVRFProxy();
    error InvalidRequestId();
    error MintFeeNotEnough();
    error InvalidParams();
    error InvalidMintTime();

    /**********************************************
     * events
     **********************************************/
    event Minted(
        address indexed receiver,
        uint256 quantity,
        uint256 startTokenId
    );
    event SignerUpdate(address indexed signer, bool valid);
    event MerkleTreeRootSet(bytes32 root);
    // burn the tokenId of from account
    event MergeTokens(
        address indexed from,
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 newTokenId
    );
    event BurnToken(address account, uint256 tokenId);
    event ChangedChainlinkVRFProxy(address chainlinkVRFProxy);
    event OpenMysteryBoxFailed(uint256 tokenId);
    event OpenMysteryBoxSuccess(uint256 tokenId, uint256 metadataId);
    event SetBaseURI(string baseURI);
    event MintFeeSet(uint256 mintFee);
    event SetProperties(Properties properties);
    event SetMintTime(MintType mintType, MintTime mintTime);
    event SetBurnRefundConfig(BurnRefundConfig[] burnRefundConfigs);
}

interface INFTManager is INFTManagerDefination {
    /**
     * @dev users in whitelist can mint mystery box
     */
    function whitelistMint(bytes32[] calldata merkleProof) external payable;

    /**
     * public mint
     * @param quantity quantities want to mint
     */
    function publicMint(uint256 quantity) external payable;

    /**
     * @dev signer mint and airdrop NFT to receivers
     */
    function airdrop(
        address[] calldata receivers,
        uint256[] calldata quantities
    ) external payable;

    /**
     * @dev bind tokenId and metadata
     */
    function openMysteryBox(uint256[] calldata tokenIds) external;

    function merge(uint256 tokenId1, uint256 tokenId2) external;

    function burn(uint256 tokenId) external;

    function setMerkleRoot(bytes32 root) external;

    function exists(uint256 tokenId) external view returns (bool);
}
