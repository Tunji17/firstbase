

## What are the main features?

- [ ] Same contract address deployment across multiple EVM chains (ETH/BSC/POL/EVM compliant) - Needs infura change to Moralis RPC or other multi chain RPC
- [ ] Manually BURN Buy Back Tax, pool funds (ETH/MATIC/BNB) and use to buy liquidity or burn the purchased tokens (MATIC)
- [ ] Liquidity Tax increases liquidity supply (MATIC/ETH/BNB) automatically
- [ ] Project/Charity/Development Wallets Tax (MATIC/ETH/BNB) (Different % for buy & sell)
- [ ] Reflections, auto distribute of token (NATIVE TOKEN) - Same as Baby Doge/Safemoon
- [ ] Buy / sell fee (DIFFERENT % ON BUY/SELL/TRANSFER) - Needs %'s to be seperated for each tax - See https://cliffordinu.io/ contract
- [x] Exclude / include a wallet from taxes/rewards
- [x] Exclude a wallet from fees
- [x] Blacklist / whitelist a wallet
- [ ] Pausable
- [x] Anti whale (Set max wallet %, exclude marketing, giveaway & other wallets)
- [ ] Really basic documentation for novice users & non crypto users
- [ ] Test deployments with verified working components for each above task
- [ ] Successful live chain deployment with verified ABI on each chain

### Next main target:
- [ ] Permissionless bridge, with auto liquidity taxes to keep bridge chain pools liquid - Being done by other contributor

### Future targets:
- [ ] Upgrade contract via proxy


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
