# DefidoContractForGood

Try running some of the following tasks:

## Prerequisites

```shell
set up correct RPC_API in hardhat.config.js
set up ACCOUNT_PRIVATE_KEY in hardhat.config.js using an account with no existing transactions
```

## Blockchains Supported

- Polygon
- Ethereum
- Binance Smart Chain

## Deploy contracts

```shell
npm install
npx hardhat compile
set correct UNISWAP_ROUTER in deploy.js
npx hardhat run scripts/deploy.js --network <config name from hardhat.config.js>
```

Copy token address from console
Copy ABI from `artifacts/contracts/Token.sol/Token.json`

Head over [here](https://oneclickdapp.com/) for a UI to interact with the token
