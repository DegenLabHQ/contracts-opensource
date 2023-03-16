import { parseEther } from "ethers/lib/utils";
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
            "0x93246E7F1618d7016A569a5F3E7B161DAb078d2d",
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

  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "updateSigners",
    ["0x4E9E367B15cb69f3cddD161ADE8044dBAF0c74F7"],
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
    "setExtraReward",
    parseEther("8")
  );

  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "setBeta",
    true
  );

  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "setIncarnationLimit",
    2
  );
};
func.tags = ["Portal"];

export default func;
