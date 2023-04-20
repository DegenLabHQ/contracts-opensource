import { DeployFunction } from "hardhat-deploy/types";
import { formatBytes32String, parseEther } from "ethers/lib/utils";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get, execute } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  const rbt = await get("RBT");

  await deploy("RebornPortal", {
    from: deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: [
            rbt.address,
            owner,
            "Degen Tombstone",
            "RIP",
            // VRFCoordinatorV2 on bnb chain test https://testnet.bscscan.com/address/0x6A2AAd07396B36Fe02a22b33cf443582f682c82f
            "0x6A2AAd07396B36Fe02a22b33cf443582f682c82f",
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
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });

  await execute(
    "RebornPortal",
    { from: owner, log: true },
    "updateSigners",
    ["0x803470638940Ec595B40397cbAa597439DE55907"],
    []
  );

  // set refer reward
  await execute(
    "RebornPortal",
    { from: owner, log: true },
    "setReferrerRewardFee",
    800,
    200,
    0
  );
  await execute(
    "RebornPortal",
    { from: owner, log: true },
    "setReferrerRewardFee",
    1800,
    200,
    1
  );

  // await execute(
  //   "RebornPortal",
  //   { from: owner, log: true },
  //   "setExtraReward",
  //   parseEther("8")
  // );

  await execute(
    "RebornPortal",
    { from: owner, log: true },
    "setIncarnationLimit",
    100
  );

  await execute(
    "RebornPortal",
    { from: owner, log: true },
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
