import { ethers } from "hardhat";
import { expect } from "chai";

import {
  keccak256,
  solidityKeccak256,
  defaultAbiCoder,
} from "ethers/lib/utils";
import { MerkleTree } from "merkletreejs";
import { generageTestAccount } from "./helper";

describe("NFTManager Test", async function () {
  before(async function () {
    const signers = await ethers.getSigners();
    this.owner = signers[0];

    const NFTManager = await ethers.getContractFactory("NFTManager");
    this.nftManager = await NFTManager.deploy();
    await this.nftManager.deployed();
    await this.nftManager.initialize(this.owner.address);
  });

  it("should merkle tree verified", async function () {
    const accountList = await generageTestAccount(10);
    const whitelist = accountList.map((account) =>
      keccak256(keccak256(defaultAbiCoder.encode(["address"], [account])))
    );

    const tree = new MerkleTree(whitelist, keccak256, { sort: true });
    const root = tree.getHexRoot();

    await this.nftManager.setMerkleRoot(root);

    for (const account of accountList) {
      const leaf = keccak256(
        keccak256(defaultAbiCoder.encode(["address"], [account]))
      );
      const proof = tree.getHexProof(leaf);
      const verified = await this.nftManager.checkWhiteList(proof, account);
      expect(verified).to.be.eq(true);
    }
  });
});
