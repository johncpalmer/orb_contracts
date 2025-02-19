import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
import { resolve } from "path";

dotenv.config({ path: resolve(__dirname, ".env") });

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    "optimism-sepolia": {
      url: process.env.OPTIMISM_SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    "optimism-mainnet": {
      url: process.env.OPTIMISM_MAINNET_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: {
      optimisticEthereum: process.env.OPTIMISM_ETHERSCAN_API_KEY || "",
      optimisticSepolia: process.env.OPTIMISM_ETHERSCAN_API_KEY || "",
    },
  },
};

export default config;