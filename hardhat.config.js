require("@nomiclabs/hardhat-waffle");
require('dotenv').config();
//
// const INFURA_PROJECT_ID = "";
// const ACCOUNT_PRIVATE_KEY = "";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  defaultNetwork: "hardhat",
  networks: {
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      // gasPrice: 180000000000,
      accounts: [`${process.env.MAINNET_PRIVATE_KEY}`]
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [`${process.env.GOERLI_PRIVATE_KEY}`]
    },
    hardhat: {
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      allowUnlimitedContractSize: false,
      gasPrice: 87500000000,
      // blockGasLimit: 0x1fffffffffffff,
      // forking: {    // option should be deactivated by default as it slows down tests significantly
      //  //url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,  // for mainnet fork
      //   url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,   // for rinkeby fork
      // }
    },
  }
};
