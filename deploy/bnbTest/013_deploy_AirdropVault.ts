import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get, execute } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  const rbt = await get("RBT");
  const portal = await get("RebornPortal");

  await deploy("AirdropVault", {
    from: deployer,
    args: [portal.address, rbt.address],
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });

  const airdropVault = await get("AirdropVault");

  // set vault for portal
  await execute(
    "RebornPortal",
    { from: owner, log: true },
    "setAirdropVault",
    airdropVault.address
  );
};
func.tags = ["AirdropVault"];

export default func;
