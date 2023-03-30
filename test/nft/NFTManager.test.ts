import { ethers } from "hardhat";
import { expect, assert } from "chai";

import { keccak256, defaultAbiCoder, hexlify } from "ethers/lib/utils";
import { MerkleTree } from "merkletreejs";
import { generageTestAccount } from "./helper";
import metadataList from "./mockMetadatalist.json";
import { BigNumber } from "ethers";

function rarityToNumber(rarity: string): number {
  switch (rarity) {
    case "Legendary":
      return 0;
    case "Uncommon":
      return 1;
    case "Common":
      return 2;
    case "Epic":
      return 3;
    case "Rare":
      return 4;
    default:
      return 7;
  }
}

function tokenTypeToNumber(tokenType: string): number {
  return tokenType === "Degens" ? 0 : 1;
}

describe("NFTManager Test", async function () {
  before(async function () {
    const signers = await ethers.getSigners();
    this.owner = signers[0];

    const NFTManager = await ethers.getContractFactory("NFTManager");
    this.nftManager = await NFTManager.deploy();
    await this.nftManager.deployed();
    await this.nftManager.initialize(this.owner.address);

    const DegenNFT = await ethers.getContractFactory("DegenNFT");
    this.degenNFT = await DegenNFT.deploy();
    await this.degenNFT.deployed();
    await this.degenNFT.initialize("Degen2009", "D2009", this.owner.address);
    await this.degenNFT.setManager(this.nftManager.address);

    await this.nftManager.setDegenNFT(this.degenNFT.address);

    const DegenNFTMock = await ethers.getContractFactory("DegenNFTMock");
    this.degenNFTMock = await DegenNFTMock.deploy();
    await this.degenNFTMock.deployed();
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

  it("Should set bucket success && verify property", async function () {
    const metadatas = metadataList.map((item) => [
      item.token_id,
      hexlify(Number(item.hero_id)),
      hexlify(rarityToNumber(item.rarity)),
      hexlify(tokenTypeToNumber(item.type)),
    ]);

    const metadataGroups = [];
    for (let i = 0; i < metadatas.length; i += 16) {
      metadataGroups.push(metadatas.slice(i, i + 16));
    }

    const buckets = [];
    const compactDatas = [];
    for (let i = 0; i < metadataGroups.length; i++) {
      buckets.push(i);

      const group = metadataGroups[i];
      const compactData = await this.degenNFTMock.generateCompactData(group);
      console.log("compactData", BigNumber.from(compactData).toString());
      compactDatas.push(compactData);
    }

    await this.nftManager
      .connect(this.owner)
      .openMysteryBox(buckets, compactDatas);
    for (let i = 0; i < metadataList.length; i++) {
      const metadata = metadataList[i];
      const [nameId, rarity, tokenType] = await this.degenNFT.getProperty(
        metadata.token_id
      );

      const [mTokenId, mNameId, mRarity, mTokenType] = metadatas[i];
      assert.equal(nameId, mNameId);
      assert.equal(rarity, mRarity.valueOf());
      assert.equal(tokenType, mTokenType.valueOf());
    }
  });
});
