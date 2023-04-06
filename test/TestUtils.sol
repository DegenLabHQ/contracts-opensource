// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {RBT} from "src/RBT.sol";
import "forge-std/Test.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

library TestUtils {
    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    bytes32 internal constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    bytes32 public constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    function deployRBT(address owner) public returns (RBT token) {
        token = new RBT();
        token.initialize("REBORN", "RBT", 10e10 ether, owner);

        // auto set owner as minter
        vm.prank(owner);
        address[] memory minterToAdd = new address[](1);
        minterToAdd[0] = owner;
        address[] memory minterToRemove;
        token.updateMinter(minterToAdd, minterToRemove);
    }

    function permitRBT(
        uint256 private_key,
        RBT rbt_,
        address spender
    )
        public
        view
        returns (
            uint256 permitAmount,
            uint256 deadline,
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        permitAmount = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        deadline = block.timestamp + 100;
        address user = vm.addr(private_key);
        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                user,
                spender,
                permitAmount,
                rbt_.nonces(user),
                deadline
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(abi.encodePacked(rbt_.name())),
                keccak256("1"),
                block.chainid,
                address(rbt_)
            )
        );

        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(
            domainSeparator,
            structHash
        );

        // sign
        (v, r, s) = vm.sign(private_key, hash);
    }
}
