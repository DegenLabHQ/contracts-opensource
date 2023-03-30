import { formatBytes32String, parseEther } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  await deploy("RBT", {
    from: degen_deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: [
            "DegenReborn Token",
            "DEGEN",
            parseEther(Number(10 ** 14).toString()),
            degen_deployer,
          ],
        },
      },
    },
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });
};
func.tags = ["RBT"];

export default func;
