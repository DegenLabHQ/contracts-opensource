import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";
import fs from "fs-extra";

export default async function exportRebornPortalAbi(
  params: any,
  hre: HardhatRuntimeEnvironment
): Promise<void> {
  const { get } = hre.deployments;

  const abi = [
    ...(await get("RebornPortal")).abi,
    ...(await get("PortalLib")).abi,
  ];

  fs.writeFileSync("portal.abi.json", JSON.stringify(abi));
}
