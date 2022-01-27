# DefidoContractForGood

Try running some of the following tasks:

## Prerequisites

```shell
set up INFURA_PROJECT_ID in hardhat.config.js
set up ACCOUNT_PRIVATE_KEY in hardhat.config.js using an account with no existing transactions
```

## Blockchains Supported

- Goerli
- rinkeby

## Deploy contracts

```shell
npm install
npx hardhat compile
scripts/deploy.sh goerli rinkeby
```

Copy token address from console
Copy ABI from `artifacts/contracts/Token.sol/Token.json`

Head over [here](https://oneclickdapp.com/) for a UI to interact with the token
