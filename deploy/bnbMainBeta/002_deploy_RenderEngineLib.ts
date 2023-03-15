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
  });
  await deploy("Renderer", {
    from: degen_deployer,
    log: true,
    libraries: { RenderConstant: (await get("RenderConstant")).address },
  });
};
func.tags = ["RenderEngineLib"];

export default func;
