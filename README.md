- [x] Same contract address deployment across multiple EVM chains (ETH/BSC/POL/EVM compliant)
- [x] Manually BURN Buy Back Tax, pool funds (ETH/MATIC/BNB) and use to buy liquidity or burn the purchased tokens (MATIC)
- [x] Liquidity Tax increases liquidity supply (MATIC/ETH/BNB)
- [x] Project/Charity/Development Wallets Tax (MATIC/ETH/BNB)
- [x] Reflections (NATIVE TOKEN)
- [x] Buy / sell fee (DIFFERENT % ON BUY/SELL/TRANSFER)
- [x] Exclude / include a wallet from taxes/rewards
- [x] Exclude a wallet from fees
- [x] Blacklist / whitelist a wallet
- [x] Pausable
- [x] Anti whale (Set max wallet %, exclude marketing, giveaway & other wallets)
- [ ] Really basic documentation for novice users & non crypto users
- [ ] Test deployments with verified working components for each above task
- [ ] Successful live chain deployment with verified ABI on each chain

### Next main target:
- [ ] Permissionless bridge, with auto liquidity taxes to keep bridge chain pools liquid

### Main features:

- Reflections
- Support for Marketing, Charity, Dev & other wallets (Auto converted into the native token, such as MATIC, ETH, BNB etc)
- Buy backs for manual burns (Also converted to the native token)
- Auto liquidity tax (Also converted into native token & put into a liquidity pool)
- Anti whale maximum holding amounts (Stop bots & whales buying lots for little at the start, you can exclude a team wallet or charity wallet from limits)
- Different taxes for buy & sell
- Multiple chain, single contract (Similar to EverRise, setup on BSC/ETH/POL/AVAX & many more ERC20 compliant chains with a single contract address!)
- Whitelist addresses from taxes/reflections (Don't tax a certain wallet or don't reward a certain wallet)
- Blacklist a wallet from owning a token & receiving reflections
- Pause the contract incase of emergency



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
