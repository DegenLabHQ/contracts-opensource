import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("RenderConstant", {
    from: deployer,
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });
  await deploy("Renderer", {
    from: deployer,
    log: true,
    libraries: { RenderConstant: (await get("RenderConstant")).address },
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });
};
func.tags = ["RenderEngineLib"];

export default func;
