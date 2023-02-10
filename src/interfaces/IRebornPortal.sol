// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IRebornDefination {
    enum TALENT {
        Degen,
        Gifted,
        Genius
    }

    enum PROPERTIES {
        BASIC,
        C,
        B,
        A,
        S
    }

    struct Innate {
        TALENT talent;
        PROPERTIES properties;
    }

    struct LifeDetail {
        bytes32 seed;
        address creator;
        uint16 age;
        uint16 round;
        uint64 nothing;
        uint128 cost;
        uint128 reward;
    }

    struct Pool {
        uint256 totalAmount;
    }

    struct Portfolio {
        uint256 accumulativeAmount;
    }

    event Incarnate(
        address indexed user,
        uint256 indexed talentPoint,
        uint256 indexed PropertyPoint,
        TALENT talent,
        PROPERTIES properties,
        uint256 indulgences,
        uint256 tokenId
    );

    event Engrave(
        bytes32 indexed seed,
        address indexed user,
        uint256 indexed score,
        uint256 reward
    );

    event Infuse(address user, uint256 tokenId, uint256 amount);

    event Dry(address user, uint256 tokenId, uint256 amount);

    event NewSoupPrice(uint256 price);

    event NewPricePoint(uint256 price);

    event SignerUpdate(address signer, bool valid);

    error InsufficientAmount();
    error NotSigner();
    error AlreadEngraved();
}

interface IRebornPortal is IRebornDefination {
    /** init enter and buy */
    function incarnate(Innate memory innate) external payable;

    /** init enter and buy with permit signature */
    function incarnate(
        Innate memory innate,
        uint256 amount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external payable;

    /** save data on chain and get reward */
    function engrave(
        bytes32 seed,
        address user,
        uint256 reward,
        uint256 score,
        uint256 age,
        uint256 locate
    ) external;

    /// @dev stake $REBORN on this tombstone
    function infuse(uint256 tokenId, uint256 amount) external;

    /// @dev unstake $REBORN on this tombstone
    function dry(uint256 tokenId, uint256 amount) external;

    /** set soup price */
    function setSoupPrice(uint256 price) external;

    /** set price and point */
    function setPriceAndPoint(uint256 price) external;
}
