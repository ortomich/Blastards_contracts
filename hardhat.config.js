/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomicfoundation/hardhat-toolbox")
// require('@openzeppelin/hardhat-upgrades');

require("dotenv").config();

const CUSTOM_RPC_URL = process.env.CUSTOM_RPC_URL || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {},
        blast_sepolia: {
          url: CUSTOM_RPC_URL,
          accounts: [PRIVATE_KEY]
       }
    },
    etherscan: {
      apiKey: {
        blast_sepolia: "blast_sepolia", // apiKey is not required, just set a placeholder
      },
      customChains: [
        {
          network: "blast_sepolia",
          chainId: 168587773,
          urls: {
            apiURL: "https://api.routescan.io/v2/network/testnet/evm/168587773/etherscan",
            browserURL: "https://testnet.blastscan.io"
          }
        }
      ]
    },
    solidity: {
        compilers: [
          {
            version: "0.8.20",
        }
        ],
    },
};
