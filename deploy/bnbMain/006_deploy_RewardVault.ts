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

  await deploy("RewardVault", {
    from: degen_deployer,
    args: [portal.address, rbt.address],
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });

  const vault = await get("RewardVault");

  // set vault for portal
  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "setVault",
    vault.address
  );
};
func.tags = ["Vault"];

export default func;
