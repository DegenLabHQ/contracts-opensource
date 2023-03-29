import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  await deploy("RewardDistributor", {
    from: deployer,
    args: [owner],
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });
};

func.tags = ["RewardDistributor"];
export default func;
