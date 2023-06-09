// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ERC721Upgradeable} from "./oz/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "./oz/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "./oz/contracts-upgradeable/security/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "./oz/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BitMapsUpgradeable} from "./oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2Upgradeable} from "src/modified/VRFConsumerBaseV2Upgradeable.sol";
import {SafeOwnableUpgradeable} from "./utils/SafeOwnableUpgradeable.sol";
import {IRebornPortal} from "src/interfaces/IRebornPortal.sol";
import {IBurnPool} from "src/interfaces/IBurnPool.sol";
import {RebornPortalStorage} from "src/RebornPortalStorage.sol";
import {RBT} from "src/RBT.sol";
import {RewardVault} from "src/RewardVault.sol";
import {RankUpgradeable} from "src/RankUpgradeable.sol";
import {Renderer} from "src/lib/Renderer.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {PortalLib} from "src/PortalLib.sol";
import {FastArray} from "src/lib/FastArray.sol";
import {IPiggyBank} from "./interfaces/IPiggyBank.sol";
import {PiggyBank} from "src/PiggyBank.sol";
import {AirdropVault} from "src/AirdropVault.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RebornPortal is
    IRebornPortal,
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    RebornPortalStorage,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    AutomationCompatible,
    RankUpgradeable,
    VRFConsumerBaseV2Upgradeable
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using FastArray for FastArray.Data;

    /**
     * @dev initialize function
     * @param rebornToken_ $REBORN token address
     * @param owner_ owner address
     * @param name_ ERC712 name
     * @param symbol_ ERC721 symbol
     * @param vrfCoordinator_ chainlink vrf coordinator_ address
     */
    function initialize(
        RBT rebornToken_,
        address owner_,
        string memory name_,
        string memory symbol_,
        address vrfCoordinator_
    ) public initializer {
        if (address(rebornToken_) == address(0)) {
            revert ZeroAddressSet();
        }
        rebornToken = rebornToken_;
        __Ownable_init(owner_);
        __ERC721_init(name_, symbol_);
        __ReentrancyGuard_init();
        __Pausable_init();
        __VRFConsumerBaseV2_init(vrfCoordinator_);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @inheritdoc IRebornPortal
     */
    function incarnate(
        InnateParams calldata innate,
        address referrer,
        SoupParams calldata soupParams
    )
        external
        payable
        override
        whenNotStoped
        nonReentrant
        checkIncarnationCount
    {
        _refer(referrer);
        _incarnate(innate, soupParams);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function incarnate(
        InnateParams calldata innate,
        address referrer,
        SoupParams calldata soupParams,
        PermitParams calldata permitParams
    )
        external
        payable
        override
        whenNotStoped
        nonReentrant
        checkIncarnationCount
    {
        _refer(referrer);
        _permit(
            permitParams.amount,
            permitParams.deadline,
            permitParams.r,
            permitParams.s,
            permitParams.v
        );

        _incarnate(innate, soupParams);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function engrave(
        bytes32 seed,
        address user,
        uint256 lifeReward,
        uint256 boostReward,
        uint256 score,
        uint256 age,
        uint256 nativeCost,
        uint256 rebornCost,
        string calldata creatorName
    ) external override onlySigner {
        if (_seeds.get(uint256(seed))) {
            revert SameSeed();
        }
        _seeds.set(uint256(seed));

        uint256 tokenId;
        uint256 totalReward;
        unchecked {
            // tokenId auto increment
            tokenId = ++idx + (block.chainid * 1e18);

            totalReward = lifeReward + boostReward;
        }

        details[tokenId] = LifeDetail(
            seed,
            user,
            uint96(totalReward),
            uint96(rebornCost),
            uint16(age),
            uint16(++rounds[user]),
            uint64(score),
            uint48(nativeCost / 10 ** 12),
            creatorName
        );
        // mint erc721
        _safeMint(user, tokenId);
        // send $REBORN reward
        vault.reward(user, totalReward);

        // let tokenId enter the score rank
        _enterScoreRank(tokenId, score);

        PortalLib._vaultRewardToRefs(
            referrals,
            rewardFees,
            vault,
            user,
            lifeReward
        );

        emit Engrave(seed, user, tokenId, score, totalReward);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function baptise(
        address user,
        uint256 amount,
        uint256 baptiseType
    ) external override onlySigner {
        vault.reward(user, amount);

        emit Baptise(user, amount, baptiseType);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) external override whenNotStoped {
        _infuse(tokenId, amount, tributeDirection);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection,
        uint256 permitAmount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external override whenNotStoped {
        _permit(permitAmount, deadline, r, s, v);
        _infuse(tokenId, amount, tributeDirection);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function switchPool(
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) external override whenNotStoped {
        _decreaseFromPool(fromTokenId, amount);
        _increaseToPool(toTokenId, amount, tributeDirection);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function claimNativeDrops(
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) external override whenNotPaused {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, totalAmount)))
        );

        bool valid = MerkleProof.verify(merkleProof, _dropNativeRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }

        uint256 remainingNativeAmount = totalAmount -
            _airdropDebt[msg.sender].nativeDebt;

        if (remainingNativeAmount == 0) {
            revert NoRemainingReward();
        }

        _airdropDebt[msg.sender].nativeDebt = uint128(totalAmount);

        airdropVault.rewardNative(msg.sender, remainingNativeAmount);

        emit ClaimNativeAirDrop(remainingNativeAmount);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function claimDegenDrops(
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) external override whenNotPaused {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, totalAmount)))
        );

        bool valid = MerkleProof.verify(merkleProof, _dropDegenRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }

        uint256 remainingDegenAmount = totalAmount -
            _airdropDebt[msg.sender].degenDebt;

        if (remainingDegenAmount == 0) {
            revert NoRemainingReward();
        }

        _airdropDebt[msg.sender].degenDebt = uint128(totalAmount);

        airdropVault.rewardDegen(msg.sender, remainingDegenAmount);

        emit ClaimDegenAirDrop(remainingDegenAmount);
    }

    /**
     * @dev Upkeep perform of chainlink automation
     */
    function performUpkeep(
        bytes calldata performData
    ) external override whenNotStoped {
        (uint256 t, uint256 id) = abi.decode(performData, (uint256, uint256));

        if (t == 1) {
            _requestDropReborn();
        } else if (t == 2) {
            _requestDropNative();
        } else if (t == 3) {
            _fulfillDropReborn(id);
        } else if (t == 4) {
            _fulfillDropNative(id);
        }
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function toNextSeason() external onlyOwner {
        piggyBank.stop(_season);

        unchecked {
            _season += 1;
        }

        // update piggyBank
        piggyBank.newSeason(_season, block.timestamp);

        // pause the contract
        _pause();

        // 16% jackpot to next season
        _seasonData[_season]._jackpot =
            (_seasonData[_season - 1]._jackpot * 16) /
            100;

        emit NewSeason(_season);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function setCharProperty(
        uint256[] calldata tokenIds,
        PortalLib.CharacterParams[] calldata charParams
    ) external onlySigner {
        PortalLib.setCharProperty(tokenIds, charParams, _characterProperties);
    }

    function setNativeDropRoot(
        bytes32 nativeDropRoot,
        uint256 timestamp
    ) external onlySigner {
        _dropNativeRoot = nativeDropRoot;

        if (_dropConf._lockRequestDropNative == false) {
            revert CannotSetRootWithoutAirdropLock();
        }
        _dropConf._lockRequestDropNative = false;

        // update last drop timestamp, no back to specfic hour, for frontend show
        _dropConf._nativeDropLastUpdate = uint32(block.timestamp);

        emit NativeDropRootSet(nativeDropRoot, timestamp);
    }

    function setDegenDropRoot(
        bytes32 degenDropRoot,
        uint256 timestamp
    ) external onlySigner {
        _dropDegenRoot = degenDropRoot;

        if (_dropConf._lockRequestDropReborn == false) {
            revert CannotSetRootWithoutAirdropLock();
        }

        _dropConf._lockRequestDropReborn = false;

        // update last drop timestamp, no back to specfic hour, for frontend show
        _dropConf._rebornDropLastUpdate = uint32(block.timestamp);
        emit DegenDropRootSet(degenDropRoot, timestamp);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function setDropConf(
        PortalLib.AirdropConf calldata conf
    ) external override onlyOwner {
        _dropConf = conf;
        emit PortalLib.NewDropConf(conf);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function setVrfConf(
        PortalLib.VrfConf calldata conf
    ) external override onlyOwner {
        _vrfConf = conf;
        emit PortalLib.NewVrfConf(conf);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function setCurseMultiplier(
        uint256 multiplier
    ) external override onlyOwner {
        _curseMultiplier = uint16(multiplier);
        emit CurseMultiplierSet(multiplier);
    }

    /**
     * @dev set vault
     * @param vault_ new vault address
     */
    function setVault(RewardVault vault_) external onlyOwner {
        vault = vault_;
        emit VaultSet(address(vault_));
    }

    /**
     * @dev set airdrop vault
     * @param vault_ new airdrop vault address
     */
    function setAirdropVault(AirdropVault vault_) external onlyOwner {
        airdropVault = vault_;
        emit AirdropVaultSet(address(vault_));
    }

    /**
     * @dev set incarnation limit
     */
    function setIncarnationLimit(uint256 limit) external onlyOwner {
        _incarnateCountLimit = limit;
        emit NewIncarnationLimit(limit);
    }

    /**
     * @dev withdraw token from vault
     * @param to the address which owner withdraw token to
     */
    function withdrawVault(address to) external whenPaused onlyOwner {
        vault.withdrawEmergency(to);
    }

    /**
     * @dev withdraw token from airdrop vault
     * @param to the address which owner withdraw token to
     */
    function withdrawAirdropVault(address to) external whenPaused onlyOwner {
        airdropVault.withdrawEmergency(to);
    }

    /**
     * @dev burn $REBORN from burn pool
     * @param amount burn from burn pool
     */
    function burnFromBurnPool(uint256 amount) external onlyOwner {
        IBurnPool(burnPool).burn(amount);
    }

    /**
     * @dev update signers
     * @param toAdd list of to be added signer
     * @param toRemove list of to be removed signer
     */
    function updateSigners(
        address[] calldata toAdd,
        address[] calldata toRemove
    ) external onlyOwner {
        PortalLib._updateSigners(signers, toAdd, toRemove);
    }

    /**
     * @dev forging with permit
     */
    function forging(
        uint256 tokenId,
        uint256 toLevel,
        PermitParams calldata permitParams
    ) external {
        _permit(
            permitParams.amount,
            permitParams.deadline,
            permitParams.r,
            permitParams.s,
            permitParams.v
        );
        _forging(tokenId, toLevel);
    }

    function forging(uint256 tokenId, uint256 toLevel) external {
        _forging(tokenId, toLevel);
    }

    function _forging(uint256 tokenId, uint256 toLevel) internal {
        uint256 currentLevel = _characterProperties[tokenId].level;
        if (currentLevel >= toLevel) {
            revert CommonError.InvalidParams();
        }
        uint256 requiredAmount;
        for (uint256 i = currentLevel; i < toLevel; i++) {
            uint256 thisLevelAmount = _forgeRequiredMaterials[i];

            if (thisLevelAmount == 0) {
                revert CommonError.InvalidParams();
            }

            unchecked {
                requiredAmount += thisLevelAmount;
            }
        }

        rebornToken.transferFrom(msg.sender, burnPool, requiredAmount);

        emit ForgedTo(tokenId, toLevel, requiredAmount);
    }

    function initializeSeason(uint256 target) external payable onlyOwner {
        PiggyBank(address(piggyBank)).initializeSeason{value: msg.value}(
            0,
            uint32(block.timestamp),
            target
        );
    }

    function setForgingRequiredAmount(
        uint256[] calldata levels,
        uint256[] calldata amounts
    ) external onlyOwner {
        uint256 levelsLength = levels.length;
        uint256 amountsLength = amounts.length;

        if (levelsLength != amountsLength) {
            revert CommonError.InvalidParams();
        }

        for (uint256 i = 0; i < levelsLength; ) {
            _forgeRequiredMaterials[levels[i]] = amounts[i];
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice mul 100 when set. eg: 8% -> 800 18%-> 1800
     * @dev set percentage of referrer reward
     * @param rewardType 0: incarnate reward 1: engrave reward
     */
    function setReferrerRewardFee(
        uint16 refL1Fee,
        uint16 refL2Fee,
        PortalLib.RewardType rewardType
    ) external onlyOwner {
        PortalLib._setReferrerRewardFee(
            rewardFees,
            refL1Fee,
            refL2Fee,
            rewardType
        );
    }

    // set burnPool address for pre burn $REBORN
    function setBurnPool(address burnPool_) external onlyOwner {
        if (burnPool_ == address(0)) {
            revert ZeroAddressSet();
        }
        burnPool = burnPool_;
    }

    function setPiggyBank(IPiggyBank piggyBank_) external onlyOwner {
        piggyBank = piggyBank_;

        emit SetNewPiggyBank(address(piggyBank_));
    }

    function setPiggyBankFee(uint16 piggyBankFee_) external onlyOwner {
        piggyBankFee = piggyBankFee_;

        emit SetNewPiggyBankFee(piggyBankFee_);
    }

    /**
     * @dev withdraw native token for reward distribution
     * @dev amount how much to withdraw
     */
    function withdrawNativeToken(
        address to,
        uint256 amount
    ) external whenPaused onlyOwner {
        payable(to).transfer(amount);
    }

    /**
     * @dev checkUpkeep for chainlink automation
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (_dropConf._dropOn == 1) {
            // first, check whether airdrop is ready and send vrf request
            if (
                block.timestamp >
                PortalLib._toLastHour(_dropConf._rebornDropLastUpdate) +
                    _dropConf._rebornDropInterval &&
                !_dropConf._lockRequestDropReborn
            ) {
                upkeepNeeded = true;
                performData = abi.encode(1, 0);
                return (upkeepNeeded, performData);
            } else if (
                block.timestamp >
                PortalLib._toLastHour(_dropConf._nativeDropLastUpdate) +
                    _dropConf._nativeDropInterval &&
                !_dropConf._lockRequestDropNative
            ) {
                upkeepNeeded = true;
                performData = abi.encode(2, 0);
                return (upkeepNeeded, performData);
            }
            // second, check pending drop and execute
            if (FastArray.length(_pendingDrops) > 0) {
                uint256 id = _pendingDrops.get(0);
                upkeepNeeded = true;
                if (_vrfRequests[id].t == AirdropVrfType.DropReborn) {
                    performData = abi.encode(3, id);
                } else if (_vrfRequests[id].t == AirdropVrfType.DropNative) {
                    performData = abi.encode(4, id);
                }
                return (upkeepNeeded, performData);
            }
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return Renderer.renderByTokenId(details, tokenId);
    }

    /**
     * @dev check whether the seed is used on-chain
     * @param seed random seed in bytes32
     */
    function seedExists(bytes32 seed) external view returns (bool) {
        return _seeds.get(uint256(seed));
    }

    /**
     * @dev run erc20 permit to approve
     */
    function _permit(
        uint256 amount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal {
        rebornToken.permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function _infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) internal {
        // it's not necessary to check the whether the address of burnPool is zero
        // as function tranferFrom does not allow transfer to zero address by default
        rebornToken.transferFrom(msg.sender, burnPool, amount);

        _increasePool(tokenId, amount, tributeDirection);

        emit Infuse(msg.sender, tokenId, amount, tributeDirection);
    }

    /**
     * @dev implementation of incarnate
     */
    function _incarnate(
        InnateParams calldata innate,
        SoupParams calldata soupParams
    ) internal {
        PortalLib._useSoupParam(
            soupParams,
            getIncarnateCount(_season, msg.sender),
            _characterProperties,
            signers
        );

        uint256 nativeFee = soupParams.soupPrice +
            innate.talentNativePrice +
            innate.propertyNativePrice;

        uint256 rebornFee = innate.talentRebornPrice +
            innate.propertyRebornPrice;

        if (msg.value < nativeFee) {
            revert InsufficientAmount();
        }

        unchecked {
            // transfer redundant native token back
            payable(msg.sender).transfer(msg.value - nativeFee);
        }

        // reward referrers
        uint256 referNativeAmount = _sendNativeRewardToRefs(
            msg.sender,
            nativeFee
        );

        //
        uint256 netNativeAmount;
        unchecked {
            netNativeAmount = nativeFee - referNativeAmount;
        }

        uint256 piggyBankAmount = (netNativeAmount * piggyBankFee) /
            PortalLib.PERCENTAGE_BASE;

        // x% to piggyBank
        piggyBank.deposit{value: piggyBankAmount}(
            _season,
            msg.sender,
            nativeFee
        );

        unchecked {
            netNativeAmount -= piggyBankAmount;
            // rest native token to to jackpot
            _seasonData[_season]._jackpot += netNativeAmount;
        }

        rebornToken.transferFrom(msg.sender, burnPool, rebornFee);

        emit Incarnate(
            msg.sender,
            soupParams.charTokenId,
            innate.talentNativePrice,
            innate.talentRebornPrice,
            innate.propertyNativePrice,
            innate.propertyRebornPrice,
            soupParams.soupPrice
        );
    }

    /**
     * @dev record referrer relationship
     */
    function _refer(address referrer) internal {
        PortalLib._refer(referrals, referrer);
    }

    /**
     * @dev airdrop to top 50 tvl pool
     * @dev directly drop to top 10
     * @dev raffle 10 from top 11 - top 50
     */
    function _fulfillDropReborn(uint256 requestId) internal onlyDropOn {
        PortalLib._fulfillDropReborn(
            requestId,
            _vrfRequests,
            _seasonData[_season],
            _dropConf,
            _pendingDrops,
            vault,
            airdropVault
        );
    }

    /**
     * @dev airdrop to top 100 tvl pool
     * @dev directly drop to top 10
     * @dev raffle 10 from top 11 - top 50
     */
    function _fulfillDropNative(uint256 requestId) internal onlyDropOn {
        PortalLib._fulfillDropNative(
            requestId,
            _vrfRequests,
            _seasonData[_season],
            _dropConf,
            _pendingDrops,
            airdropVault
        );
    }

    function _requestDropReborn() internal onlyDropOn {
        if (
            block.timestamp <
            PortalLib._toLastHour(_dropConf._rebornDropLastUpdate) +
                _dropConf._rebornDropInterval &&
            !_dropConf._lockRequestDropReborn
        ) {
            revert CommonError.InvalidParams();
        }

        if (_dropConf._lockRequestDropReborn) {
            revert DropLocked();
        }
        _dropConf._lockRequestDropReborn = true;
        // raffle
        uint256 requestId = VRFCoordinatorV2Interface(vrfCoordinator)
            .requestRandomWords(
                _vrfConf.keyHash,
                _vrfConf.s_subscriptionId,
                _vrfConf.requestConfirmations,
                _vrfConf.callbackGasLimit,
                _vrfConf.numWords
            );

        _vrfRequests[requestId].exists = true;
        _vrfRequests[requestId].t = AirdropVrfType.DropReborn;
    }

    function _requestDropNative() internal onlyDropOn {
        if (
            block.timestamp <
            PortalLib._toLastHour(_dropConf._nativeDropLastUpdate) +
                _dropConf._nativeDropInterval &&
            !_dropConf._lockRequestDropNative
        ) {
            revert CommonError.InvalidParams();
        }

        if (_dropConf._lockRequestDropNative) {
            revert DropLocked();
        }
        _dropConf._lockRequestDropNative = true;

        // raffle
        uint256 requestId = VRFCoordinatorV2Interface(vrfCoordinator)
            .requestRandomWords(
                _vrfConf.keyHash,
                _vrfConf.s_subscriptionId,
                _vrfConf.requestConfirmations,
                _vrfConf.callbackGasLimit,
                _vrfConf.numWords
            );

        _vrfRequests[requestId].exists = true;
        _vrfRequests[requestId].t = AirdropVrfType.DropNative;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        if (
            !_vrfRequests[requestId].fulfilled && _vrfRequests[requestId].exists
        ) {
            _vrfRequests[requestId].randomWords = randomWords[0];
            _vrfRequests[requestId].fulfilled = true;

            _pendingDrops.insert(requestId);
        }
    }

    /**
     * @dev send NativeToken to referrers
     */
    function _sendNativeRewardToRefs(
        address account,
        uint256 amount
    ) internal returns (uint256) {
        return
            PortalLib._sendNativeRewardToRefs(
                referrals,
                rewardFees,
                account,
                amount
            );
    }

    /**
     * @dev decrease amount from pool of switch from
     */
    function _decreaseFromPool(uint256 tokenId, uint256 amount) internal {
        (uint256 totalTribute, TributeDirection tributeDirection) = PortalLib
            ._decreaseFromPool(
                tokenId,
                amount,
                _curseMultiplier,
                _seasonData[_season]
            );

        _enterTvlRank(tokenId, totalTribute);

        emit DecreaseFromPool(msg.sender, tokenId, amount, tributeDirection);
    }

    /**
     * @dev increase amount to pool of switch to
     */
    function _increaseToPool(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) internal {
        uint256 restakeAmount;
        unchecked {
            restakeAmount = (amount * 95) / 100;
        }

        _increasePool(tokenId, restakeAmount, tributeDirection);

        emit IncreaseToPool(
            msg.sender,
            tokenId,
            restakeAmount,
            tributeDirection
        );
    }

    function _increasePool(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) internal {
        uint256 totalPoolTribute = PortalLib._increasePool(
            tokenId,
            amount,
            _curseMultiplier,
            tributeDirection,
            _seasonData[_season]
        );

        _enterTvlRank(tokenId, totalPoolTribute);
    }

    function getCoinday(
        uint256 tokenId,
        address account
    ) public view returns (uint256 userCoinday, uint256 poolCoinday) {
        (userCoinday, poolCoinday) = PortalLib.getCoinday(
            tokenId,
            account,
            _seasonData[_season]
        );
    }

    /**
     * @dev returns referrer and referer reward
     * @return ref1  level1 of referrer. direct referrer
     * @return ref1Reward  level 1 referrer reward
     * @return ref2  level2 of referrer. referrer's referrer
     * @return ref2Reward  level 2 referrer reward
     */
    function calculateReferReward(
        address account,
        uint256 amount,
        PortalLib.RewardType rewardType
    )
        public
        view
        returns (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        )
    {
        return
            PortalLib._calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                rewardType
            );
    }

    /**
     * @dev read pool attribute
     */
    function getPool(
        uint256 tokenId
    ) public view returns (PortalLib.Pool memory) {
        return _seasonData[_season].pools[tokenId];
    }

    /**
     * @dev read pool attribute
     */
    function getPortfolio(
        address user,
        uint256 tokenId
    ) public view returns (PortalLib.Portfolio memory) {
        return _seasonData[_season].portfolios[user][tokenId];
    }

    function getIncarnateCount(
        uint256 season,
        address user
    ) public view returns (uint256) {
        return _incarnateCounts[season][user];
    }

    function getIncarnateLimit() public view returns (uint256) {
        return _incarnateCountLimit;
    }

    function getDropConf() public view returns (PortalLib.AirdropConf memory) {
        return _dropConf;
    }

    /**
     * A -> B -> C: B: level1 A: level2
     * @dev referrer1: level1 of referrers referrer2: level2 of referrers
     */
    function getReferrers(
        address account
    ) public view returns (address referrer1, address referrer2) {
        referrer1 = referrals[account];
        referrer2 = referrals[referrer1];
    }

    /**
     * @dev return the jackpot amount of current season
     */
    function getJackPot() public view returns (uint256) {
        return _seasonData[_season]._jackpot;
    }

    function getAirdropDebt(
        address user
    ) public view returns (AirDropDebt memory) {
        return _airdropDebt[user];
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

    function _checkDropOn() internal view {
        if (_dropConf._dropOn == 0) {
            revert DropOff();
        }
    }

    function _checkIncarnationCount() internal {
        uint256 currentIncarnateCount = getIncarnateCount(_season, msg.sender);
        if (currentIncarnateCount >= _incarnateCountLimit) {
            revert IncarnationExceedLimit();
        }

        unchecked {
            _incarnateCounts[_season][msg.sender] = currentIncarnateCount + 1;
        }
    }

    /**
     * @dev check signer implementation
     */
    function _checkSigner() internal view {
        if (!signers[msg.sender]) {
            revert CommonError.NotSigner();
        }
    }

    function _checkStoped() internal view {
        if (piggyBank.checkIsSeasonEnd(_season)) {
            revert SeasonAlreadyStoped();
        }

        if (paused()) {
            revert PausablePaused();
        }
    }

    modifier onlySigner() {
        _checkSigner();
        _;
    }

    /**
     * @dev check incarnation Count and auto increment if it meets
     */
    modifier checkIncarnationCount() {
        _checkIncarnationCount();
        _;
    }

    /**
     * @dev only allowed when drop is on
     */
    modifier onlyDropOn() {
        _checkDropOn();
        _;
    }

    modifier whenNotStoped() {
        _checkStoped();
        _;
    }
}
