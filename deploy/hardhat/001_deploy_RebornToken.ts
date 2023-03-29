import { formatBytes32String, parseEther } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  await deploy("RBT", {
    from: deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: [
            "Degen Reborn Token",
            "$REBORN",
            parseEther(Number(10 ** 9).toString()),
            owner,
          ],
        },
      },
    },
    deterministicDeployment: formatBytes32String("DegenReborn"),

    log: true,
  });
};
func.tags = ["RBT"];

export default func;
