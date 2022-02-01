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
  
  /* 
  Set the UNISWAP_ROUTER to the router address of the swap you want to use. What is a swap? A swap is technology used to exchange one token for another,
  such as on the Binance Smart Chain (BSC), you will exchange BNB for a token such as $BABYDOGE, which is a great little dog coin or you could use $BASE,
  the native token name of the wonderful Defido Coin. We need a swap to be able exchange tokens, and UNISWAP V2 router is the main router used.

  HOW TO:
  Use the below router address for the specific chain you want, we have put some of the most used chains. These all work as they are ERC20 compliant EVM chains.
  */
  
  const UNISWAP_ROUTER = {
    ETH: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, // (ETH) ETHEREUM CHAIN UNISWAP
    POL: 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, // (POL) POLYGON CHAIN QUICKSWAP
    BSC: 0x10ED43C718714eb63d5aA57B78B54704E256024E, // (BSC) BINANCE CHAIN PANCAKESWAP
    FANTOM: 0xF491e7B69E4244ad4002BC14e878a34207E38c29 // (FANTOM) AVAX NETWORK PANGOLIN EXCHANGE
  }


  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  /*
   This async function below called 'Factory' pulls in the CREATE2 install factory function for setting up the contract address on each chain. Why do we need this?
   We need this to enable a single contract address to be used across every chain we use. This means, the same contract address is used for every chain we deploy to. 
   Be careful with this, you must deploy the first transaction on each chain, or the second transaction, or the third transaction on each chain to get the same address.
   If you deploy 1 chain with the first transaction on that chain, then you try to deploy the 2nd transaction on BSC, you're going to get a different contract address.
   Best to setup a fresh wallet, deploy for the first time on each chain. If you make a mistake, send a dummy transaction and do it on the second transaction. 
  
  /*
  Below is the beginning of the deployment from the terminal. To deploy the Defido contract you need to use the terminal on your windows, linux or Mac computer.
  */
  
  const Factory = await hre.ethers.getContractFactory("Factory");
  // The console will log that the deployment script is running.
  console.log("Deploying ...");
  // Deploy the factory function.
  const factory = await Factory.deploy();
  // Get the confirmation
  await factory.deployed();
  // Console log the factory address
  console.log("Factory deployed to:", factory.address)
  /*
    REFERENCE TOKEN: https://etherscan.io/address/0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE (Shiba Inu) we will use SHIB as an example here.
    "factory.getBytecode("Defido Coin", "BASE", "9", "5", "5", "1000000000", UNISWAP_ROUTER.ETH)"
    
    Here is where we set the chain information for deployment of your token. 
    
    1) "Defido Coin", Defido Coin is the name of the token
    2) "9", This is the decimals, don't worry about this. A developer should focus on this part. Usually it will be 9 or 18.
    3) "5", "5", "1000000000" // EXPLAIN THIS PART 
  */
  const tokenBytecode = await factory.getBytecode("Defido Coin", "BASE", "9", "5", "5", "1000000000", UNISWAP_ROUTER.ETH); //Change your router address based on the chain you are using. BSC = Binance, POL = Polygon etc
  const tokenAddress = await factory.getAddress(tokenBytecode);
  console.log('Token to be deployed to:', tokenAddress);
  // Get the tokens contract address // See here for example SHIB https://etherscan.io/address/ (THIS PART is the address: 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE)
  // Console log the address to the terminal.

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
