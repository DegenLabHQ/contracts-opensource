// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {DeployProxy} from "foundry-upgrades/utils/DeployProxy.sol";

import "src/mock/PortalMock.sol";
import {RBT} from "src/RBT.sol";
import {RewardVault} from "src/RewardVault.sol";
import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {EventDefination} from "src/test/EventDefination.sol";
import {TestUtils} from "test/TestUtils.sol";
import {ECDSAUpgradeable} from "@oz/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC20Upgradeable} from "@oz/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {BurnPool} from "src/BurnPool.sol";
import {VRFCoordinatorV2Mock} from "src/mock/VRFCoordinatorV2Mock.sol";
import "src/AirdropVault.sol";

import "src/mock/PiggyBankMock.sol";

contract RebornPortalBaseTest is Test, IRebornDefination, EventDefination {
    uint256 public constant SOUP_PRICE = 0.01 * 1 ether;
    PortalMock portal;
    PiggyBankMock piggyBank;
    RBT rbt;
    BurnPool burnPool;
    AirdropVault _airdropVault;
    address owner = vm.addr(2);
    address _user = vm.addr(10);
    address _signer = vm.addr(11);
    uint256 internal _seedIndex;
    // address on bnb testnet
    address internal _vrfCoordinator;
    // solhint-disable-next-line var-name-mixedcase

    modifier deployAll() {
        // ignore effect of chainId to tokenId
        vm.chainId(0);

        rbt = TestUtils.deployRBT(owner);
        deal(address(rbt), _user, 100000 ether);

        // deploy vrf coordinator
        _vrfCoordinator = address(new VRFCoordinatorV2Mock());

        // deploy portal
        portal = deployPortal();
        vm.prank(owner);
        address[] memory toAdd = new address[](1);
        toAdd[0] = _signer;
        address[] memory toRemove;
        portal.updateSigners(toAdd, toRemove);
        vm.startPrank(owner);
        portal.setIncarnationLimit(type(uint256).max);
        vm.stopPrank();

        // deploy piggy bank
        piggyBank = deployPiggyBank();
        vm.startPrank(owner);
        piggyBank.setCoundDownTimeLong(7 * 1 days);
        vm.stopPrank();

        deal(owner, UINT256_MAX);
        // set piggy bank
        vm.startPrank(owner);
        portal.setPiggyBank(IPiggyBank(address(piggyBank)));
        portal.setPiggyBankFee(800);
        // intialize piggybank
        portal.initializeSeason{value: 0.1 ether}(1 ether);
        vm.stopPrank();

        // deploy burn pool
        burnPool = new BurnPool(address(portal), address(rbt));
        vm.prank(owner);
        portal.setBurnPool(address(burnPool));

        // deploy vault
        RewardVault vault = new RewardVault(address(portal), address(rbt));
        // set vault with infinite degen
        deal(address(rbt), address(vault), UINT256_MAX);
        vm.prank(owner);
        portal.setVault(vault);

        // deploy airdrop vault
        _airdropVault = new AirdropVault(address(portal), address(rbt));
        vm.prank(owner);
        portal.setAirdropVault(_airdropVault);

        // add portal as minter
        vm.prank(owner);
        address[] memory minterToAdd = new address[](1);
        minterToAdd[0] = address(portal);
        address[] memory minterToRemove;
        rbt.updateMinter(minterToAdd, minterToRemove);
        _;
    }

    function setUp() public virtual deployAll {}

    function deployPortal() public returns (PortalMock portal_) {
        portal_ = new PortalMock();
        portal_.initialize(
            rbt,
            owner,
            "Degen Tombstone",
            "RIP",
            _vrfCoordinator
        );
    }

    function deployPiggyBank() public returns (PiggyBankMock piggyBank_) {
        piggyBank_ = new PiggyBankMock();
        piggyBank_.initialize(owner, address(portal));
    }

    function mockEngraveFromLowToHigh() public returns (uint256 r) {
        r = ++_seedIndex;
        deal(address(rbt), address(portal.vault()), r);

        vm.prank(_signer);
        portal.engrave(
            keccak256(abi.encode(r)),
            _user,
            r,
            0,
            r,
            r,
            r,
            r,
            "@DegenReborn"
        );
    }

    function mockEngraveFromHighToLow() public returns (uint256 r) {
        r = 1 ether - ++_seedIndex;
        deal(address(rbt), address(portal.vault()), r);

        vm.prank(_signer);
        portal.engrave(
            keccak256(abi.encode(r)),
            _user,
            r,
            0,
            r,
            r,
            r,
            r,
            "@DegenReborn"
        );
    }

    function mockEngravesIncre(uint256 count) public {
        for (uint i = 0; i < count; i++) {
            mockEngraveFromLowToHigh();
        }
    }

    function mockEngravesDecre(uint256 count) public {
        for (uint i = 0; i < count; i++) {
            mockEngraveFromHighToLow();
        }
    }

    function mockEngravesAndInfuses(uint256 count) public {
        for (uint i = 0; i < count; i++) {
            uint256 t = mockEngraveFromLowToHigh();
            mockInfuse(_user, t, 1);
        }
    }

    function mockInfuse(address user, uint256 tokenId, uint256 amount) public {
        deal(address(rbt), user, amount);

        vm.startPrank(user);
        rbt.approve(address(portal), amount);
        portal.infuse(tokenId, amount, TributeDirection.Forward);
        vm.stopPrank();
    }

    function mockSignCharOwnership(
        address user,
        uint256 soupPrice,
        uint256 incarnateCounter,
        uint256 tokenId
    ) public view returns (uint256 deadline, bytes32 r, bytes32 s, uint8 v) {
        (deadline, r, s, v) = TestUtils.signAuthenticateSoup(
            11,
            address(portal),
            user,
            soupPrice,
            incarnateCounter,
            tokenId
        );
    }

    function mockSetOneTokenIdDefaultProperty(uint256 tokenId) public {
        vm.prank(_signer);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        PortalLib.CharacterParams[]
            memory charPs = new PortalLib.CharacterParams[](1);

        charPs[0] = PortalLib.CharacterParams(3, 28800, 0);

        portal.setCharProperty(tokenIds, charPs);
    }
}
