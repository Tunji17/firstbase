// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const [deployer] = await ethers.getSigners();
  const UNISWAP_ROUTER = {
    ETH: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, // (ETH) ETHEREUM CHAIN UNISWAP
    POL: 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, // (POL) POLYGON CHAIN QUICKSWAP
    BSC: 0x10ED43C718714eb63d5aA57B78B54704E256024E, // (BSC) BINANCE CHAIN PANCAKESWAP
    FANTOM: 0xF491e7B69E4244ad4002BC14e878a34207E38c29 // (FANTOM) AVAX NETWORK PANGOLIN EXCHANGE
  }


  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  // We get the contract to deploy
  const Factory = await hre.ethers.getContractFactory("Factory");
  console.log("Deploying ...");
  const factory = await Factory.deploy();
  await factory.deployed();
  console.log("Factory deployed to:", factory.address);

  const tokenBytecode = await factory.getBytecode("Defido Coin", "BASE", "9", "5", "5", "1000000000", UNISWAP_ROUTER.ETH); //Change your router address based on the chain you are using. BSC = Binance, POL = Polygon etc
  const tokenAddress = await factory.getAddress(tokenBytecode);
  console.log('Token to be deployed to:', tokenAddress);

  const deployTransaction = await factory.deploy(tokenBytecode, deployer.address);
  console.log('Deploy transaction hash:', deployTransaction.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
