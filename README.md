

## What are the main features?

- [ ] Same contract address deployment across multiple EVM chains (ETH/BSC/POL/EVM compliant) 
*Needs infura change to Moralis RPC or other multi chain RPC.
*Uses the CREATE2 FACTORY in 'factory.sol'

- [ ] Manually BURN Buy Back Tax, pool funds (ETH/MATIC/BNB) and use to buy liquidity or burn the purchased tokens (MATIC)

*We just top up a wallet with the native coin, ETH/MATIC/BNB at the $1000 or near mark, and then use that manually to burn the token & burn it.*
*This also has a setting where a % of every buy/sell & transfer simply sends tokens to the burn wallet*

- [ ] Liquidity Tax increases liquidity supply (MATIC/ETH/BNB) automatically


*We top up the liquidity pool after pooling $1000USD+ of native coin, we then pair it with ETH/TOKEN for example, or MATIC/TOKEN.*

- [ ] Project/Charity/Development Wallets Tax (MATIC/ETH/BNB)


*There are 4 main wallets, project, charity, development & marketing. All these wallets should be able to set different % of taxes for buy, sell and transfer.*
*These wallets are used to help teams fund the projects*

- [ ] Reflections, auto distribute of token (NATIVE TOKEN)
*This is an auto redistribution or reflections, similar to Baby Doge or Safemoon. 
*Simply by holding their token, holders will see their balances increase.
*There is different reflections based on the tax % of buy/sell and transfer taxes

- [ ] Buy / sell fee (DIFFERENT % ON BUY/SELL/TRANSFER) 
*We need to set different percentages of tax for each interaction with the contract - See https://cliffordinu.io/ contract for more details
*Buy has different taxation
*Sell has different taxation
*Transfer has different taxation

<img width="377" alt="Screen Shot 2022-02-08 at 9 56 49 pm" src="https://user-images.githubusercontent.com/95591037/152990546-3b291eef-32de-4f90-92f0-00291da4483b.png">
<img width="1150" alt="Screen Shot 2022-02-08 at 9 52 46 pm" src="https://user-images.githubusercontent.com/95591037/152990552-9597e557-7868-459d-b96a-3f817b9c5088.png">


*This contract taxes usage

- [x] Exclude / include a wallet from taxes/rewards
*Exclude wallets from all taxes or rewards

- [x] Blacklist / whitelist a wallet
*Stop a wallet from being able to hold or purchase the token

- [ ] Pausable
*Pause the contract in case of emergency

- [x] Anti whale (Set max wallet %, exclude marketing, giveaway & other wallets)
*Set a maximum amount the holder can own in %
*Set a maximum 1 time sell 
*Make sure to exclude marketing, project, contract and other wallets.

- [ ] Really basic documentation for novice users & non crypto users
*This contract is for beginners & novices. Write for them.

- [ ] Test deployments with verified working components for each above task
*Tests are needed before deployment to main chains
*Programmatic tests would be good

- [ ] Successful live chain deployment with verified ABI on each chain
*A successful working contract would be validated by Defido Coin


### Next main target:
- [ ] Permissionless bridge, with auto liquidity taxes to keep bridge chain pools liquid - Being done by other contributor
*The worlds first permissionless bridge allows for projects to automatically get bridging of their tokens from day 1


### Future targets:
- [ ] Upgrade contract via proxy
*The ability to upgrade the contract without needing to replace the contract would be super helpful for projects



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
