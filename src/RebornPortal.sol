// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IRebornPortal} from "src/interfaces/IRebornPortal.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";

import {RebornStorage} from "src/RebornStorage.sol";
import {IRebornToken} from "src/interfaces/IRebornToken.sol";
import {RenderEngine} from "src/lib/RenderEngine.sol";
import {RBT} from "src/RBT.sol";
import {RewardVault} from "src/RewardVault.sol";

contract RebornPortal is
    IRebornPortal,
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    RebornStorage,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IRebornToken;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    function initialize(
        RBT rebornToken_,
        uint256 soupPrice_,
        address owner_,
        string memory name_,
        string memory symbol_
    ) public initializer {
        rebornToken = rebornToken_;
        soupPrice = soupPrice_;
        __Ownable_init(owner_);
        __ERC721_init(name_, symbol_);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function incarnate(Innate memory innate, address referrer)
        external
        payable
        override
        whenNotPaused
        nonReentrant
    {
        _incarnate(innate);
        _refer(referrer);
    }

    /**
     * @dev incarnate
     */
    function incarnate(
        Innate memory innate,
        address referrer,
        uint256 amount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external payable override whenNotPaused nonReentrant {
        _permit(amount, deadline, r, s, v);
        _incarnate(innate);
        _refer(referrer);
    }

    /**
     * @dev engrave the result on chain and reward
     * @param seed uuid seed string without "-"  in bytes32
     */
    function engrave(
        bytes32 seed,
        address user,
        uint256 reward,
        uint256 score,
        uint256 age,
        uint256 cost
    ) external override onlySigner whenNotPaused {
        if (_seeds.get(uint256(seed))) {
            revert SameSeed();
        }
        _seeds.set(uint256(seed));

        // tokenId auto increment
        uint256 tokenId = ++idx;

        details[tokenId] = LifeDetail(
            seed,
            user,
            uint16(age),
            ++rounds[user],
            0,
            // set cost to 0 temporary, should implement later
            uint128(cost / 10**18),
            uint128(reward / 10**18),
            score
        );
        // mint erc721
        _safeMint(user, tokenId);
        // send $REBORN reward
        vault.reward(user, reward);

        // mint to referrer
        _rewardReferrer(user, reward);

        emit Engrave(seed, user, tokenId, score, reward);
    }

    /**
     * @dev baptise
     */
    function baptise(address user, uint256 amount)
        external
        override
        onlySigner
        whenNotPaused
    {
        if (baptism.get(uint160(user))) {
            revert AlreadyBaptised();
        }

        baptism.set(uint160(user));

        vault.reward(user, amount);

        emit Baptise(user, amount);
    }

    /**
     * @dev degen infuse $REBORN to tombstone
     * @dev expect for bliss
     */
    function infuse(uint256 tokenId, uint256 amount)
        external
        override
        whenNotPaused
    {
        _requireMinted(tokenId);

        rebornToken.transferFrom(msg.sender, address(this), amount);

        Pool storage pool = pools[tokenId];
        pool.totalAmount += amount;

        Portfolio storage portfolio = portfolios[msg.sender][tokenId];
        portfolio.accumulativeAmount += amount;

        emit Infuse(msg.sender, tokenId, amount);
    }

    /**
     * @dev degen get $REBORN back
     */
    function dry(uint256 tokenId, uint256 amount)
        external
        override
        whenNotPaused
    {
        Pool storage pool = pools[tokenId];
        pool.totalAmount -= amount;

        Portfolio storage portfolio = portfolios[msg.sender][tokenId];
        portfolio.accumulativeAmount -= amount;

        rebornToken.transfer(msg.sender, amount);

        emit Dry(msg.sender, tokenId, amount);
    }

    /**
     * @dev set soup price
     */
    function setSoupPrice(uint256 price) external override onlyOwner {
        soupPrice = price;
        emit NewSoupPrice(price);
    }

    /**
     * @dev set vault
     */
    function setVault(RewardVault vault_) external onlyOwner {
        vault = vault_;
    }

    /**
     * @dev withdraw token from vault
     */
    function withdrawVault(address to) external onlyOwner {
        vault.withdrawEmergency(to);
    }

    /**
     * @dev update signer
     */
    function updateSigners(
        address[] calldata toAdd,
        address[] calldata toRemove
    ) public onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], true);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete signers[toRemove[i]];
            emit SignerUpdate(toRemove[i], false);
        }
    }

    /**
     * @dev withdraw native token for reward distribution
     */
    function withdrawNativeToken(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory metadata = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    name(),
                    '","description":"',
                    "",
                    '","image":"',
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            RenderEngine.renderSvg(
                                details[tokenId].seed,
                                details[tokenId].score,
                                details[tokenId].round,
                                details[tokenId].age,
                                details[tokenId].creator,
                                details[tokenId].cost
                            )
                        )
                    ),
                    '","attributes": ',
                    RenderEngine.renderTrait(
                        details[tokenId].seed,
                        details[tokenId].score,
                        details[tokenId].round,
                        details[tokenId].age,
                        details[tokenId].creator,
                        details[tokenId].reward,
                        details[tokenId].cost
                    ),
                    "}"
                )
            )
        );

        return string.concat("data:application/json;base64,", metadata);
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

    /**
     * @dev implementation of incarnate
     */
    function _incarnate(Innate memory innate) internal {
        if (msg.value < soupPrice) {
            revert InsufficientAmount();
        }
        // transfer redundant native token back
        payable(msg.sender).transfer(msg.value - soupPrice);

        // reborn token needed
        uint256 rbtAmount = innate.talentPrice + innate.propertyPrice;

        /// burn token directly
        rebornToken.burnFrom(msg.sender, rbtAmount);

        emit Incarnate(msg.sender, innate.talentPrice, innate.propertyPrice);
    }

    /**
     * @dev record referrer relationship, only one layer
     */
    function _refer(address referrer) internal {
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = referrer;
            emit Refer(msg.sender, referrer);
        }
    }

    /**
     * @dev mint refer reward to referee's referrer
     */
    function _rewardReferrer(address referee, uint256 amount) internal {
        (address referrar, uint256 referReward) = calculateReferReward(
            referee,
            amount
        );
        if (referrar != address(0)) {
            vault.reward(referrar, referReward);
            emit ReferReward(referrar, referReward);
        }
    }

    /**
     * @dev returns refereral and refer reward
     * @param referee referee address
     * @param amount reward to the referee, ERC20 amount
     */
    function calculateReferReward(address referee, uint256 amount)
        public
        view
        returns (address referrar, uint256 referReward)
    {
        referrar = referrals[referee];
        // refer reward ratio is temporary 0.2
        referReward = amount / 5;
    }

    /**
     * @dev read pool attribute
     */
    function getPool(uint256 tokenId) public view returns (Pool memory) {
        _requireMinted(tokenId);
        return pools[tokenId];
    }

    /**
     * @dev ceil a uint256 and remove decimal
     */
    function _ceilUint256(uint256 value, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        if (value - (value / 10**decimal) * 10**decimal == 0) {
            return value / 10**decimal;
        } else {
            return value / 10**decimal + 1;
        }
    }

    /**
     * @dev ceil a uint256 to the multiple of 5
     */
    function _ceilUint256ToMultipleOfFive(uint256 value)
        internal
        pure
        returns (uint256)
    {
        if (value % 5 == 0) {
            return value;
        }
        return value + (5 - (value % 5));
    }

    /**
     * @dev check signer implementation
     */
    function _checkSigner() internal view {
        if (!signers[msg.sender]) {
            revert NotSigner();
        }
    }

    /**
     * @dev only allowed signer address can do something
     */
    modifier onlySigner() {
        _checkSigner();
        _;
    }
}
