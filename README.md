# Defido Coin - Contract for good
## This contract is provided free for any project, regardless of your financial purpose. 
### The only requirement is, the contract stays MIT licensed & make a note to defido.com, Defido Coin & other source code contributors.

## What is the mission?

Provide a free open source contract that covers 90% of the use cases projects require, whilst making it extremely simple to use for a beginner.

## Who is this for? 

Crypto novices, non technical founders, beginner developers, developers who are helping the previous three listed, or developers who want a starting point. It is supposed to give enough of what most users would need. As well as giving advanced features that are not common in contracts, such as single contract address deployment & the worlds first integrated permissionless bridge. 

## Why make this free and OSS?

We see token launchers as a tool for deep lock in, we see the need for something that covers 90% of the use cases that users will have, a single contract to offer most of the needs, although currently this contract does not cover that, we hope to keep expanding the Defido Coin - Contract for good to cover the 90%

## Why did Defido Coin make this?

We find solidity contracts to be complex, and so do others, we wanted to create a contract that even a non programmer could understand or deploy. In the spirit of true decentralised finance. We wanted a contract that gave us the ability to turn on or off the features we wanted, and most of the features we wanted, we could find repeated in many other contracts. But they were not OSS.

## What are the main features?

- [x] Same contract address deployment across multiple EVM chains (ETH/BSC/POL/EVM compliant)
- [ ] Manually BURN Buy Back Tax, pool funds (ETH/MATIC/BNB) and use to buy liquidity or burn the purchased tokens (MATIC)
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

### Main features extended:

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

# Instructions section:

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
