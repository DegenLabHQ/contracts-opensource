import { DeployFunction } from "hardhat-deploy/types";
import { formatBytes32String, parseEther } from "ethers/lib/utils";

enum StageType {
  Invalid,
  WhitelistMint,
  PublicMint,
  Merge,
}

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get, execute } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  await deploy("NFTManager", {
    from: degen_deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: [degen_deployer],
        },
      },
    },
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });

  const degenNFT = await get("DegenNFT");
  await execute(
    "NFTManager",
    { from: degen_deployer, log: true },
    "setDegenNFT",
    degenNFT.address
  );

  // set whitelist mint time
  await execute(
    "NFTManager",
    { from: degen_deployer, log: true },
    "setMintTime",
    StageType.WhitelistMint,
    [1680069600, 1680350400]
  );
  // set public mint time
  await execute(
    "NFTManager",
    { from: degen_deployer, log: true },
    "setMintTime",
    StageType.PublicMint,
    [1680091200, 1680350400]
  );

  // await execute(
  //   "NFTManager",
  //   { from: owner, log: true },
  //   "setMintTime",
  //   StageType.Merge,
  //   []
  // );

  // set mint fee
  await execute(
    "NFTManager",
    { from: degen_deployer, log: true },
    "setMintFee",
    parseEther("0.2").toString()
  );

  const nftManager = await get("NFTManager");
  await execute(
    "DegenNFT",
    { from: degen_deployer, log: true },
    "setManager",
    nftManager.address
  );
};

func.tags = ["NFTManager"];

export default func;
