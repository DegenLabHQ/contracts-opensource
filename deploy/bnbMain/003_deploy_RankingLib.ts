import { DeployFunction } from "hardhat-deploy/types";
import { formatBytes32String } from "ethers/lib/utils";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  await deploy("FastArray", {
    from: degen_deployer,
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });
  await deploy("RankingRedBlackTree", {
    from: degen_deployer,
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });
  await deploy("SingleRanking", {
    from: degen_deployer,
    log: true,
    libraries: {
      FastArray: (await get("FastArray")).address,
      RankingRedBlackTree: (await get("RankingRedBlackTree")).address,
    },
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });
  await deploy("DegenRank", {
    from: degen_deployer,
    libraries: {
      SingleRanking: (await get("SingleRanking")).address,
      FastArray: (await get("FastArray")).address,
      RankingRedBlackTree: (await get("RankingRedBlackTree")).address,
    },
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });
};

func.tags = ["RankingLib"];

export default func;
