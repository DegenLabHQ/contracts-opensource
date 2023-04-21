import { DeployFunction } from "hardhat-deploy/types";
import { formatBytes32String, parseEther } from "ethers/lib/utils";

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
            "Degen Tombstone",
            "RIP",
            // VRFCoordinatorV2 on bnb chain mainnet https://bscscan.com/address/0xc587d9053cd1118f25F645F9E08BB98c9712A4EE
            "0xc587d9053cd1118f25F645F9E08BB98c9712A4EE",
          ],
        },
      },
    },
    libraries: {
      RenderConstant: (await get("RenderConstant")).address,
      RenderConstant2: (await get("RenderConstant2")).address,
      Renderer: (await get("Renderer")).address,
      FastArray: (await get("FastArray")).address,
      RankingRedBlackTree: (await get("RankingRedBlackTree")).address,
      SingleRanking: (await get("SingleRanking")).address,
      DegenRank: (await get("DegenRank")).address,
      PortalLib: (await get("PortalLib")).address,
    },
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });

  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "updateSigners",
    // https://bscscan.com/address/0xe3b0DF60032E05E0f08559f8F4962368ba47339B
    ["0xe3b0DF60032E05E0f08559f8F4962368ba47339B"],
    []
  );

  // set refer reward
  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "setReferrerRewardFee",
    800,
    200,
    0
  );

  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "setReferrerRewardFee",
    1800,
    200,
    1
  );

  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "setIncarnationLimit",
    1000
  );

  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "setForgingRequiredAmount",
    [1, 2, 3, 4],
    [
      parseEther(Number(50_000_000).toString()),
      parseEther(Number(100_000_000).toString()),
      parseEther(Number(200_000_000).toString()),
      parseEther(Number(500_000_000).toString()),
    ]
  );
};
func.tags = ["Portal"];

export default func;
