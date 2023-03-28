import { ethers } from "hardhat";
const { Wallet } = ethers;

export enum Rarity {
  Legendary,
  Epic,
  Rare,
  Uncommon,
  Common,
}

export enum TokenType {
  Degen,
  Shard,
}

export const metadataList = [
  {
    name: "CZ",
    rarity: Rarity.Legendary,
    tokenType: TokenType.Shard,
  },
  {
    name: "CZ",
    rarity: Rarity.Legendary,
    tokenType: TokenType.Shard,
  },
  {
    name: "SBF",
    rarity: Rarity.Epic,
    tokenType: TokenType.Shard,
  },
  {
    name: "SBF",
    rarity: Rarity.Epic,
    tokenType: TokenType.Shard,
  },
  {
    name: "CZ",
    rarity: Rarity.Legendary,
    tokenType: TokenType.Degen,
  },
  {
    name: "CZ",
    rarity: Rarity.Legendary,
    tokenType: TokenType.Degen,
  },
];

export function generageTestAccount(n: number) {
  const accountList: string[] = [];
  for (let i = 0; i < n; i++) {
    const { address } = Wallet.createRandom();
    accountList.push(address);
  }

  return accountList;
}
