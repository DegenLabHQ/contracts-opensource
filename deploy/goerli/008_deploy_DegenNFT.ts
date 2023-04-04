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
          args: ["Degen2009", "D2009", owner],
        },
      },
    },
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
    log: true,
  });

  // const nftManager = await get("NFTManager");
  // await execute(
  //   "DegenNFT",
  //   { from: owner, log: true },
  //   "setManager",
  //   nftManager.address
  // );

  // set baseUri
  await execute(
    "DegenNFT",
    { from: owner, log: true },
    "setBaseURI",
    "https://cdn.degenreborn.xyz/degenz/nft/"
  );
};

func.tags = ["DegenNFT"];

export default func;
