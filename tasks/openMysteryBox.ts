import { BigNumber, Contract } from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";
import { abi } from "../deployments/goerli/NFTManager_Implementation.json";

const buckets: number[] = [];
const compactDatas: BigNumber[] = [];

export default async function openMysteryBox(
  params: any,
  hre: HardhatRuntimeEnvironment
): Promise<void> {
  const ethers = hre.ethers;
  const [signer] = await ethers.getSigners();
  const nftManager = new Contract(
    "0xcF665D1e1F23Ad6C57C04a3852FB29a2E360FF2C",
    abi,
    signer
  );
  const tx = await nftManager
    .connect(signer)
    .openMysteryBox(buckets, compactDatas);
  await tx.wait();
}
