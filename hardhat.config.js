const dotenv = require("dotenv");

dotenv.config(); // load env vars from .env

require("@nomicfoundation/hardhat-toolbox");

const { ARCHIVE_URL } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      { version: "0.4.16" },
      { version: "0.4.24" },
      { version: "0.5.12" },
      { version: "0.6.12" },
      { version: "0.7.0" },
      { version: "0.7.6" },
      { version: "0.8.0" },
      { version: "0.8.23" }
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: ARCHIVE_URL,
        blockNumber: 11800000,
      },
      // accounts: [{privateKey: TESTING_ACCOUNT_PRIVATE_KEY, balance: ethers.parseEther('10000').toString()}],
    },
  },
};
