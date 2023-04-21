import { formatBytes32String, parseEther } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy, get, execute } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  const portal = await get("RebornPortal");

  await deploy("PiggyBank", {
    from: degen_deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: [degen_deployer, portal.address],
        },
      },
    },
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn"),
  });

  const piggyBank = await get("PiggyBank");
  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "setPiggyBank",
    piggyBank.address
  );

  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true },
    "setPiggyBankFee",
    1800
  );

  await execute(
    "PiggyBank",
    { from: degen_deployer, log: true },
    "setMultiple",
    200
  );
  await execute(
    "PiggyBank",
    { from: degen_deployer, log: true },
    "setMinTimeLong",
    7 * 24 * 3600
  );

  await execute(
    "RebornPortal",
    { from: degen_deployer, log: true, value: parseEther("10") },
    "initializeSeason",
    parseEther("1")
  );
};

func.tags = ["PiggyBank"];

export default func;
