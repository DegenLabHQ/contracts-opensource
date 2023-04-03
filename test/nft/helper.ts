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
export function rarityToNumber(rarity: string): number {
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

export function generageTestAccount(n: number) {
  const accountList: string[] = [];
  for (let i = 0; i < n; i++) {
    const { address } = Wallet.createRandom();
    accountList.push(address);
  }

  return accountList;
}
