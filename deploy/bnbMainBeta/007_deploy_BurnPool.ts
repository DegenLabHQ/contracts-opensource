import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get, execute } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  const rbt = await get("RBT");
  const portal = await get("RebornPortal");

  await deploy("BurnPool", {
    from: degen_deployer,
    args: [portal.address, rbt.address],
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Beta"),

  });

  const burnPool = await get("BurnPool");
  //   set burn pool for portal
  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "setBurnPool",
    burnPool.address
  );
};

func.tags = ["BurnPool"];
export default func;
