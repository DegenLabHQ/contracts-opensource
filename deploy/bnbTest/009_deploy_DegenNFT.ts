import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get, execute } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  await deploy("DegenNFT", {
    from: deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: ["Degen2009", "Degen2009", owner],
        },
      },
    },
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });

  const nftManager = await get("NFTManager");
  await execute(
    "DegenNFT",
    { from: owner, log: true },
    "setManager",
    nftManager.address
  );
};

func.tags = ["DegenNFT"];

export default func;
