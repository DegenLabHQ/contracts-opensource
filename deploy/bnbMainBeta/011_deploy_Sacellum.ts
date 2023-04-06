import { formatBytes32String } from "ethers/lib/utils";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
}) {
  const { deploy } = deployments;
  const { degen_deployer } = await getNamedAccounts();

  await deploy("Sacellum", {
    from: degen_deployer,
    proxy: {
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        init: {
          methodName: "initialize",
          args: [
            // $CZ: https://bscscan.com/address/0x5b2B3EE2E434fdBD370B3358b4F951e2b12b3aa7
            "0x5b2B3EE2E434fdBD370B3358b4F951e2b12b3aa7",
            // $DEGEN: https://bscscan.com/address/0x1a131F7B106D58f33eAf0fE5B47DB2f2045E5732
            "0x1a131F7B106D58f33eAf0fE5B47DB2f2045E5732",
            // Safe multisig https://bscscan.com/address/0xa3Cad344c89990C557844766e25AD5ADDbF3B445
            "0xa3Cad344c89990C557844766e25AD5ADDbF3B445",
          ],
        },
      },
    },
    log: true,
    deterministicDeployment: formatBytes32String("DegenReborn_Test"),
  });
};

func.tags = ["Sacellum"];

export default func;
