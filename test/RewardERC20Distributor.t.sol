// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "src/RewardERC20Distributor.sol";
import "src/RBT.sol";
import {IRewardDistributorDef} from "src/interfaces/IRewardDistributor.sol";
import "test/TestUtils.sol";

contract RewardERC20DistributorTest is Test, IRewardDistributorDef {
    RewardERC20Distributor rd;
    RBT rbt;
    address _owner = address(2);

    function setUp() public {
        rbt = TestUtils.deployRBT(_owner);
        rd = new RewardERC20Distributor(_owner, IERC20(address(rbt)));
    }

    function testZeroERC20SetFail() public {
        vm.expectRevert(ZeroAddressSet.selector);
        new RewardERC20Distributor(address(0), IERC20(address(0)));

        vm.expectRevert(ZeroAddressSet.selector);
        new RewardERC20Distributor(address(1), IERC20(address(0)));

        vm.expectRevert(ZeroAddressSet.selector);
        new RewardERC20Distributor(address(0), IERC20(address(1)));

        new RewardERC20Distributor(address(1), IERC20(address(1)));
    }

    function testSetZeroRootFail() public {
        vm.expectRevert(ZeroRootSet.selector);
        vm.prank(_owner);
        rd.setMerkleRoot(bytes32(0));
    }

    function testSetRootTwiceFail(bytes32 root) public {
        vm.assume(root != bytes32(0));
        vm.prank(_owner);
        rd.setMerkleRoot(root);

        vm.expectRevert(RootSetTwice.selector);
        vm.prank(_owner);
        rd.setMerkleRoot(root);
    }

    function testClaim() public {}
}
