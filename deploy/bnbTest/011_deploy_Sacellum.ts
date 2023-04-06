import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  const cz = await get("RBT");
  const degen = await get("RBTDup");

  await deploy("Sacellum", {
    from: deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: [cz.address, degen.address, owner],
        },
      },
    },
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });
};

func.tags = ["Sacellum"];

export default func;
