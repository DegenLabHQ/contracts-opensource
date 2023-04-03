import { ethers } from "hardhat";
import { expect, assert } from "chai";

import { keccak256, defaultAbiCoder, hexlify } from "ethers/lib/utils";
import { MerkleTree } from "merkletreejs";
import { generageTestAccount, rarityToNumber } from "./helper";
import metadataList from "./mockMetadatalist.json";

describe("NFTManager Test", async function () {
  before(async function () {
    const signers = await ethers.getSigners();
    this.owner = signers[0];
    this.signer = signers[1];

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

  it("Should openMysteryBox success", async function () {
    const metadatas = metadataList.map((item) => [
      hexlify(item.hero_id),
      hexlify(rarityToNumber(item.rarity)),
      hexlify(Number(item.is_shard)),
    ]);
    const tokenIds = metadataList.map((item) => item.token_id);

    await this.nftManager
      .connect(this.owner)
      .updateSigners([this.signer.address], []);

    await this.nftManager
      .connect(this.signer)
      .openMysteryBox(tokenIds, metadatas);

    for (let i = 0; i < metadataList.length; i++) {
      const element = metadataList[i];
      const [nameId, rarity, tokenType] = await this.degenNFT.getProperty(
        element.token_id
      );

      assert.equal(nameId.valueOf(), element.hero_id);
      assert.equal(rarity.valueOf(), rarityToNumber(element.rarity));
      assert.equal(tokenType.valueOf(), Number(element.is_shard));
    }
  });
});
