import { DeployFunction } from "hardhat-deploy/types";
import { parseEther } from "ethers/lib/utils";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  const rbt = await get("RBT");

  await deploy("RebornPortal", {
    from: degen_deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: [
            rbt.address,
            "0xa23a69CB8aE1259937F1e6b51e76a53F3DEaA988",
            "DegenReborn Tombstone (Beta)",
            "RIP(B)",
            // VRFCoordinatorV2 on bnb chain mainnet https://bscscan.com/address/0xc587d9053cd1118f25F645F9E08BB98c9712A4EE
            "0xc587d9053cd1118f25F645F9E08BB98c9712A4EE",
          ],
        },
      },
    },
    libraries: {
      RenderConstant: (await get("RenderConstant")).address,
      Renderer: (await get("Renderer")).address,
      FastArray: (await get("FastArray")).address,
      RankingRedBlackTree: (await get("RankingRedBlackTree")).address,
      SingleRanking: (await get("SingleRanking")).address,
      DegenRank: (await get("DegenRank")).address,
      PortalLib: (await get("PortalLib")).address,
    },
    log: true,
  });

  // await execute(
  //   "RebornPortal",
  //   { from: owner, log: true },
  //   "updateSigners",
  //   ["0x803470638940Ec595B40397cbAa597439DE55907"],
  //   []
  // );

  // // set refer reward
  // await execute(
  //   "RebornPortal",
  //   { from: owner, log: true },
  //   "setReferrerRewardFee",
  //   800,
  //   200,
  //   0
  // );

  // await execute(
  //   "RebornPortal",
  //   { from: owner, log: true },
  //   "setReferrerRewardFee",
  //   1800,
  //   200,
  //   0
  // );

  // await execute(
  //   "RebornPortal",
  //   { from: owner, log: true },
  //   "setExtraReward",
  //   parseEther("8")
  // );

  // await execute(
  //   "RebornPortal",
  //   { from: owner, log: true },
  //   "setBeta",
  //   true
  // );
};
func.tags = ["Portal"];

export default func;
