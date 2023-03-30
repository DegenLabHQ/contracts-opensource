import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("FastArray", {
    from: deployer,
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });
  await deploy("RankingRedBlackTree", {
    from: deployer,
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });
  await deploy("SingleRanking", {
    from: deployer,
    log: true,
    libraries: {
      FastArray: (await get("FastArray")).address,
      RankingRedBlackTree: (await get("RankingRedBlackTree")).address,
    },
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });
  await deploy("DegenRank", {
    from: deployer,
    libraries: {
      SingleRanking: (await get("SingleRanking")).address,
      FastArray: (await get("FastArray")).address,
      RankingRedBlackTree: (await get("RankingRedBlackTree")).address,
    },
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });
};

func.tags = ["RankingLib"];

export default func;
