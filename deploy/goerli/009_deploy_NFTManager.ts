import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get, execute } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  await deploy("NFTManager", {
    from: deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: [owner],
        },
      },
    },
    log: true,
  });

  const degenNFT = await get("DegenNFT");
  await execute(
    "NFTManager",
    { from: owner, log: true },
    "setDegenNFT",
    degenNFT.address
  );
};

func.tags = ["NFTManager"];

export default func;
