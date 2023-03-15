import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  await deploy("RewardDistributor", {
    from: degen_deployer,
    args: ["0xa23a69CB8aE1259937F1e6b51e76a53F3DEaA988"],
    log: true,
  });
};

func.tags = ["RewardDistributor"];
export default func;
