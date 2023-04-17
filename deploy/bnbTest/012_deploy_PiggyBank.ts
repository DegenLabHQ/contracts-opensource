import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  const portal = await get("Portal");

  await deploy("PiggyBank", {
    from: deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: [owner, portal.address],
        },
      },
    },
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });
};

func.tags = ["PiggyBank"];

export default func;
