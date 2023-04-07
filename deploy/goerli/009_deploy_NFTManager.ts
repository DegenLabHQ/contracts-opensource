import { DeployFunction } from "hardhat-deploy/types";
import { formatBytes32String, parseEther } from "ethers/lib/utils";

enum StageType {
  Invalid,
  WhitelistMint,
  PublicMint,
  Merge,
  Burn,
}

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
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
    log: true,
  });

  // const degenNFT = await get("DegenNFT");
  // await execute(
  //   "NFTManager",
  //   { from: owner, log: true },
  //   "setDegenNFT",
  //   degenNFT.address
  // );

  // const nftManager = await get("NFTManager");
  // await execute(
  //   "DegenNFT",
  //   { from: owner, log: true },
  //   "setManager",
  //   nftManager.address
  // );

  // // set whitelist mint time
  // await execute(
  //   "NFTManager",
  //   { from: owner, log: true },
  //   "setMintTime",
  //   StageType.WhitelistMint,
  //   [1680069600, 1682870400]
  // );
  // // set public mint time
  // await execute(
  //   "NFTManager",
  //   { from: owner, log: true },
  //   "setMintTime",
  //   StageType.PublicMint,
  //   [1680091200, 1682870400]
  // );

  // await execute(
  //   "NFTManager",
  //   { from: owner, log: true },
  //   "setMintTime",
  //   StageType.Merge,
  //   []
  // );

  // await execute(
  //   "NFTManager",
  //   { from: owner, log: true },
  //   "setMintTime",
  //   StageType.Burn,
  //   []
  // );

  // // set mint fee

  // await execute(
  //   "NFTManager",
  //   { from: owner, log: true },
  //   "setMintFee",
  //   parseEther("0.000002").toString()
  // );

  // TODO: set merkle tree
  // await execute("NFTManager", { from: owner, log: true }, "setMerkleRoot", "");
};

func.tags = ["NFTManager"];

export default func;
