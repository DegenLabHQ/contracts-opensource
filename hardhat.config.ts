import * as dotenv from "dotenv";

import fs from "fs";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@typechain/hardhat";
import "hardhat-deploy";
import "hardhat-preprocessor";
import "hardhat-contract-sizer";

import { HardhatUserConfig, task } from "hardhat/config";

import example from "./tasks/example";

function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean)
    .filter((v) => v.includes("@node_modules"))
    .map((line) => line.trim().split("="));
}

dotenv.config();

const deployer =
  process.env.DEPLOYER || "0x0000000000000000000000000000000000000000";
const owner = process.env.OWNER || "0x0000000000000000000000000000000000000000";
const degen_deployer =
  process.env.DEGEN_DEPLOYER || "0x0000000000000000000000000000000000000000";
const accounts = process.env.ACCOUNTS ? process.env.ACCOUNTS.split(",") : [];

task("example", "Example task").setAction(example);

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        // details: {
        //   yulDetails: {
        //     optimizerSteps: "u",
        //   },
        // },
      },
      // viaIR: true,
    },
  },
  networks: {
    hardhat: {
      gas: "auto",
      gasPrice: "auto",
      deploy: ["deploy/hardhat"],
      tags: ["hardhat"],
    },
    bnbMain: {
      url: process.env.BNB_CHAIN_URL || "",
      accounts: accounts,
      gas: "auto",
      gasPrice: "auto",
      deploy: ["deploy/bnbMain"],
      tags: ["production"],
    },
    bnbMainBeta: {
      url: process.env.BNB_CHAIN_URL || "",
      accounts: accounts,
      gas: "auto",
      gasPrice: "auto",
      deploy: ["deploy/bnbMainBeta"],
      tags: ["production"],
    },

    bnbTest: {
      url: process.env.BNB_CHAIN_TEST_URL || "",
      accounts: accounts,
      gas: "auto",
      gasPrice: "auto",
      deploy: ["deploy/bnbTest"],
      tags: ["test"],
    },
    mumbai: {
      url: process.env.POLYGON_MUMBAI_RPC_URL || "",
      accounts: accounts,
      gas: "auto",
      gasPrice: "auto",
      deploy: ["deploy/mumbai"],
      tags: ["test"],
    },
    scrollAlpha: {
      url: "https://alpha-rpc.scroll.io/l2",
      accounts: accounts,
      chainId: 534353,
      gas: "auto",
      gasPrice: "auto",
      deploy: ["deploy/scrollAlpha"],
      tags: ["test"],
    },
    goerli: {
      url: process.env.GOERLI_CHAIN_URL || "",
      accounts: accounts,
      gas: "auto",
      gasPrice: "auto",
      deploy: ["deploy/goerli"],
      tags: ["test"],
    },
    ethereum: {
      url: process.env.ETH_CHAIN_URL || "",
      accounts: accounts,
      gas: "auto",
      gasPrice: "auto",
      deploy: ["deploy/ethereum"],
      tags: ["prod"],
    },
  },
  namedAccounts: {
    deployer: {
      hardhat: 0,
      bnbTest: deployer,
      mumbai: deployer,
      scrollAlpha: deployer,
      goerli: deployer,
    },
    owner: {
      hardhat: 0,
      bnbTest: owner,
      mumbai: owner,
      scrollAlpha: owner,
      goerli: owner,
    },
    degen_deployer: {
      bnbMain: degen_deployer,
      bnbMainBeta: degen_deployer,
      ethereum: degen_deployer,
    },
  },

  paths: {
    sources: "./src", // Use ./src rather than ./contracts as Hardhat expects
    cache: "./cache_hardhat", // Use a different cache for Hardhat than Foundry
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
  deterministicDeployment: {
    // create2 factory source: https://github.com/pcaversaccio/create2deployer
    bnbMain: {
      factory: "0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2",
      deployer: "",
      funding: "",
      signedTx: "",
    },
    bnbMainBeta: {
      factory: "0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2",
      deployer: "",
      funding: "",
      signedTx: "",
    },
    ethereum: {
      factory: "0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2",
      deployer: "",
      funding: "",
      signedTx: "",
    },
    mumbai: {
      factory: "0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2",
      deployer: "",
      funding: "",
      signedTx: "",
    },
    scrollAlpha: {
      factory: "0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2",
      deployer: "",
      funding: "",
      signedTx: "",
    },
    bnbTest: {
      factory: "0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2",
      deployer: "",
      funding: "",
      signedTx: "",
    },
    goerli: {
      factory: "0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2",
      deployer: "",
      funding: "",
      signedTx: "",
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      bscTestnet: process.env.BNB_SCAN_API_KEY!,
      bsc: process.env.BNB_SCAN_API_KEY!,
      polygonMumbai: process.env.POLYGON_SCAN_API_KEY!,
      scrollAlpha: "scrollAlpha",
      goerli: process.env.GOERLI_SCAN_API_KEY!,
      mainnet: process.env.GOERLI_SCAN_API_KEY!,
    },
    customChains: [
      {
        network: "scrollAlpha",
        chainId: 534353,
        urls: {
          apiURL: "https://blockscout.scroll.io/api",
          browserURL: "https://blockscout.scroll.io",
        },
      },
    ],
  },
  contractSizer: {
    alphaSort: false,
    disambiguatePaths: false,
    runOnCompile: false,
    strict: false,
  },
  external: {
    contracts: [
      {
        artifacts:
          "node_modules/@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol/",
      },
    ],
  },
  mocha: {
    timeout: 40000,
  },
};

export default config;
