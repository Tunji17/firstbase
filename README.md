# Defido Coin - Contract for good
## This contract is provided free for any project, regardless of your financial purpose. We have chosen the MIT license. Referencing defido.com, Defido Coin, Safemoon & other projects to which this code base may have come from, would be greatly appreciated!

## What is the mission?

Provide a free open source contract that covers 90% of the use cases projects require, whilst making it extremely simple to use for a beginner.

## Who is this for? 

Crypto novices, non technical founders, beginner developers, developers who are helping the previous three listed, or developers who want a starting point. It is supposed to give enough of what most users would need. As well as giving advanced features that are not common in contracts, such as single contract address deployment & the worlds first integrated permissionless bridge. 

## Why make this free and OSS?

We see token launchers as a tool for deep lock in, we see the need for something that covers 90% of the use cases that users will have, a single contract to offer most of the needs, although currently this contract does not cover that, we hope to keep expanding the Defido Coin - Contract for good to cover the 90%

## Why did Defido Coin make this?

We find solidity contracts to be complex, and so do others, we wanted to create a contract that even a non programmer could understand or deploy. In the spirit of true decentralised finance. We wanted a contract that gave us the ability to turn on or off the features we wanted, and most of the features we wanted, we could find repeated in many other contracts. But they were not OSS.

## What are the main features?

- [ ] Same contract address deployment across multiple EVM chains (ETH/BSC/POL/EVM compliant) - Needs infura change
- [ ] Manually BURN Buy Back Tax, pool funds (ETH/MATIC/BNB) and use to buy liquidity or burn the purchased tokens (MATIC)
- [ ] Liquidity Tax increases liquidity supply (MATIC/ETH/BNB)
- [ ] Project/Charity/Development Wallets Tax (MATIC/ETH/BNB)
- [ ] Reflections (NATIVE TOKEN)
- [ ] Buy / sell fee (DIFFERENT % ON BUY/SELL/TRANSFER) - Needs %'s to be seperated for each tax
- [x] Exclude / include a wallet from taxes/rewards
- [x] Exclude a wallet from fees
- [x] Blacklist / whitelist a wallet
- [ ] Pausable
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
- Multiple chain, single contract (Similar to EverRise, setup on BSC/ETH/POL/FANTOM & many more ERC20 compliant chains with a single contract address!) as long as they support UNISWAP V2 and are the same as the EVM/ERC20, then this contract should work.
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

This contract can support any EVM compliant chain, where the swap is also a Uniswap V2 copy. We currently do not support Uniswap V3 or other swaps.

- Polygon
- Ethereum
- Binance Smart Chain

## Bridge Support

Currently the bridge can support: (More are coming soon) There is no need to signup, or pay a fee, this is the worlds first permissionless bridge!

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

## License 

MIT, free to use, in commercial or non commercial purposes.

## Contributing

Feature requests: 

If there is a particular feature you want to see in this contract, you have two options, code the implementation yourself & use on your own contract, code the implementation to our standards of beginner use and request a merge. 

Bug reporting:

Please email info@defido.com if you find a bug, don't openly disclose it.

Complaints: 

Please email info@defido.com if you have a complaint.

Code of conduct:

Openly accessible, freely available, regardless of any requirement. This contract is for anyone, place nice, be nice, remember although Defido Coin is run by a dog, you're likely still talking to a human.


