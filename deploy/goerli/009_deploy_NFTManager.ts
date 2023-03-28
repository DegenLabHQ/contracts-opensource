import { DeployFunction } from "hardhat-deploy/types";
import { parseEther } from "ethers/lib/utils";

enum MintType {
  WhitelistMint,
  PublicMint,
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
    log: true,
  });

  const degenNFT = await get("DegenNFT");
  await execute(
    "NFTManager",
    { from: owner, log: true },
    "setDegenNFT",
    degenNFT.address
  );

  // set whitelist mint time
  await execute(
    "NFTManager",
    { from: owner, log: true },
    "setMintTime",
    MintType.WhitelistMint,
    [1680069600, 1680350400]
  );
  // set public mint time
  await execute(
    "NFTManager",
    { from: owner, log: true },
    "setMintTime",
    MintType.PublicMint,
    [1680091200, 1680350400]
  );

  // set mint fee

  await execute(
    "NFTManager",
    { from: owner, log: true },
    "setMintFee",
    parseEther("0.2").toString()
  );

  // TODO: set merkle tree
  await execute("NFTManager", { from: owner, log: true }, "setMerkleRoot", "");
};

func.tags = ["NFTManager"];

export default func;
