import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("PortalLib", {
    from: deployer,
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });
};

func.tags = ["PortalLib"];

export default func;
