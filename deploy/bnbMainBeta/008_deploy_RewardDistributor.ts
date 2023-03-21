import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  await deploy("RewardDistributor", {
    from: degen_deployer,
    args: [degen_deployer],
    log: true,
  });
};

func.tags = ["RewardDistributor"];
export default func;
