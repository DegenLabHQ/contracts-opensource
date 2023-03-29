import { formatBytes32String, parseEther } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get, execute } = deployments;
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
            degen_deployer,
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
    deterministicDeployment: formatBytes32String("DegenReborn_Beta"),
  });

  // await execute(
  //   "RebornPortal",
  //   { from: degen_deployer, log: true },
  //   "updateSigners",
  //   [],
  //   []
  // );

  // set refer reward
  // await execute(
  //   "RebornPortal",
  //   { from: degen_deployer, log: true },
  //   "setReferrerRewardFee",
  //   800,
  //   200,
  //   0
  // );

  // await execute(
  //   "RebornPortal",
  //   { from: degen_deployer, log: true },
  //   "setReferrerRewardFee",
  //   1800,
  //   200,
  //   1
  // );

  // await execute(
  //   "RebornPortal",
  //   { from: degen_deployer, log: true },
  //   "setExtraReward",
  //   parseEther("8")
  // );

  // await execute(
  //   "RebornPortal",
  //   { from: degen_deployer, log: true },
  //   "setIncarnationLimit",
  //   2
  // );
};
func.tags = ["Portal"];

export default func;
