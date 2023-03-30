import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  await deploy("RenderConstant", {
    from: degen_deployer,
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Beta"),
  });
  await deploy("Renderer", {
    from: degen_deployer,
    log: true,
    libraries: { RenderConstant: (await get("RenderConstant")).address },
    deterministicDeployment: formatBytes32String("DegenReborn_Beta"),
  });
};
func.tags = ["RenderEngineLib"];

export default func;
