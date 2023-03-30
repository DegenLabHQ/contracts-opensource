import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  await deploy("DegenNFT", {
    from: degen_deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: ["Degen2009", "D2009", degen_deployer],
        },
      },
    },
    deterministicDeployment: formatBytes32String("DegenReborn"),
    log: true,
  });

  // set baseUri
  // await execute("DegenNFT", { from: owner, log: true }, "setBaseURI", "");
};

func.tags = ["DegenNFT"];

export default func;
