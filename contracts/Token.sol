//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


interface ICrossChainBridgeERC20LiquidityManager {
    function addLiquidityERC20(IERC20 token, uint256 amount) external;
    function withdrawLiquidityERC20(IERC20 token, uint256 amount) external;
    function lpTokens(address spender) external returns (bool exists, IERC20 token);

}

interface ILiquidityMiningPools {
    function stake(address tokenAddress, uint256 amount) external;
    function unstake(address tokenAddress, uint256 amount) external;
    function harvest(address tokenAddress, address stakerAddress) external;
}

// To Understand this contract, please refer to the following links: https://reflect-contract-doc.netlify.app/
contract Token is Context, IERC20, Ownable, Pausable {
    using SafeMath for uint256;
    using Address for address;

    // Addresses
    bool public _enableMarketingAddress;
    address payable public _marketingAddress;
    bool public _enableDevelopmentAddress;
    address payable public _developmentAddress;
    bool public _enableProductAddress;
    address payable public _productAddress;
    bool public _enableCharityAddress;
    address payable public _charityAddress;

    // Address used to burn a portion of tokens
    address payable public _burnAddress = payable(0x000000000000000000000000000000000000dEaD);


    // total token (t-space) supply
    uint256 private _tTotal;
    // total r-space supply (reflections) which is between (MAX.sub(_tTotal)) and MAX
    uint256 private _rTotal;

    // total token owned in t-space
    mapping(address => uint256) private _tOwned;
    // total reflections owned in r-space
    mapping(address => uint256) private _rOwned;

    mapping(address => mapping(address => uint256)) private _allowances;

    // addresses excluded from fees
    mapping(address => bool) private _isExcludedFromFee;
    // addresses excluded from rewards
    mapping(address => bool) private _isExcluded;
    // addresses blacklisted
    mapping(address => bool) private _isBlacklisted;
    // all excluded addresses
    address[] private _excluded;

    // maximum value in uint256
    uint256 private constant MAX = ~uint256(0);

    // total fee transacted
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // tax fee in percentage used for transfers
    // this value is updated to buy and sell fee and reverted after the transaction
    uint256 public _taxFee;
    uint256 private _previousTaxFee;

    // buy tax fee
    bool public _enableBuyTaxFee;
    uint256 public _buyTaxFee;

    // sell tax fee
    bool public _enableSellTaxFee;
    uint256 public _sellTaxFee;

    // liquidity fee in percentage
    uint256 public _liquidityFee;
    uint256 private _previousLiquidityFee;

    // uniswap v2 router contract
    IUniswapV2Router02 public immutable uniswapV2Router;
    // uniswap v2 pair contract address
    address public immutable uniswapV2Pair;

    // CrossChainBridge liquidity manager contract
    ICrossChainBridgeERC20LiquidityManager public immutable ccbLiquidityManager;
    ILiquidityMiningPools public immutable ccbLiquidityMiningPools;

    bool currentlySwapping;
    bool public _enableLiquidity = true;

    // maximum value for a transaction
    uint256 public _maxTxAmount;
    uint256 private _tokenSwapThreshold;

    // maximum value a wallet can hold
    uint256 public _maxHoldingAllowed;


    // BUYBACK
    bool    public _enableBuyback;
    uint256 public _buybackNativeTokenThreshold; // Native Token required to be inside the contract before a buyback will be performed
    uint256 public _buybackUpperLimit; // Maximum Token to be bought in any one trade
    uint256 public _buybackNativeTokenPercentage;  // % of Native token used to buyback tokens

    // Events
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 nativeTokenReceived,
        uint256 tokensIntoLiqudity
    );

    // Modifiers
    modifier lockTheSwap() {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }

    modifier notBlacklisted(address account) {
        require(!isBlacklisted(account), "Interacting with a blacklisted account");
        _;
    }

    modifier notCreatingAWhale(address account) {
        _;
        uint256 bal = balanceOf(account);
        require(bal < _maxHoldingAllowed, "Whales are not allowed");
    }

    // Constructor
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 taxFee_,
        uint256 liquidityFee_,
        uint256 totalSupply_,
        address _router,
        ICrossChainBridgeERC20LiquidityManager _ccbLiquidityManager,
        ILiquidityMiningPools _liquidityMiningPools
    ) {

        // Instantiate variables
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _taxFee = taxFee_;
        _previousTaxFee = taxFee_;
        _liquidityFee = liquidityFee_;
        _previousLiquidityFee = liquidityFee_;

        _tTotal = totalSupply_.mul(10**_decimals);
        _rTotal = (MAX - (MAX % _tTotal));
        _maxTxAmount = (totalSupply_.div(200)).mul(10**_decimals);
        _tokenSwapThreshold = (totalSupply_.div(2000)).mul(10**_decimals);
        _maxHoldingAllowed = (totalSupply_.div(20)).mul(10**_decimals);

        _rOwned[_msgSender()] = _rTotal;

        // sets uniswap router contract
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // sets cross-chain bridge contracts
        ccbLiquidityManager = _ccbLiquidityManager;
        ccbLiquidityMiningPools = _liquidityMiningPools;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // Functions

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /**
     * @notice checks the balance of an account
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /**
     * @notice Used to transfer tokens from caller to recipient
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @notice checks amount of token spender  is allowed to send
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @notice used to withdraws Native token from the contract
     */
    function withdrawNative(uint256 amount) public onlyOwner() {
        if(amount == 0) payable(owner()).transfer(address(this).balance);
        else payable(owner()).transfer(amount);
    }

    /**
     * @notice used to transfers Native token to an address
     */
    function transferNativeTokenToAddress(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    /**
     * @notice used by spender to transfer token from sender to recipient
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @notice used to increase allowance given to a spender
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @notice used to decrease allowance given to a spender
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @notice used to check if an address is excluded from rewards
     */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /**
     * @notice used to check total fees collected by contract
     */
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    /**
     * @notice used to get gross or net reflection amount when given a transfer amount
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    /**
     * @notice used to get token amount when given a reflection amount
     */
    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    /**
     * @notice used to exclude address from rewards
     */
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /**
     * @notice used to include excluded account in rewards
     */
    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /**
     * @notice used to check if the account is already blacklisted
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    /**
     * @notice used to blacklist an address
     */
    function addToBlacklist(address account) external onlyOwner {
        _isBlacklisted[account] = true;
    }

    /**
     * @notice used to unblacklist an address
     */
    function removeFromBlacklist(address account) external onlyOwner {
        _isBlacklisted[account] = false;
    }

    /**
     * @notice used to exclude address from paying fees
     */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /**
     * @notice used to include excluded account in paying fees
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @notice used to set a tax fee percentage which accounts will be charged for tranfers
     */
    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    /**
     * @notice used to set a tax fee percentage which accounts will be charged for buying tokens
     */
    function setBuyTaxFeeAndPercent(bool _enabled, uint256 taxFee) external onlyOwner {
        _enableBuyTaxFee = _enabled;
        _buyTaxFee = taxFee;
    }

    /**
     * @notice used to set a tax fee percentage which accounts will be charged for selling tokens
     */
    function setSellTaxFeeAndPercent(bool _enabled, uint256 taxFee) external onlyOwner {
        _enableSellTaxFee = _enabled;
        _sellTaxFee = taxFee;
    }

    /**
     * @notice used to set a liquidity tax fee percentage
     */
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    /**
     * @notice used to set if buyback is enabled
     */
    function setBuybackEnabled(bool _enabled) external onlyOwner() {
        _enableBuyback = _enabled;
    }

    /**
     * @notice used to set if buyback is enabled and other parameters required for buyback
     */
    function setBuyback(
        bool _enabled,
        uint256 nativeTokenThreshold,
        uint256 upperLimit,
        uint256 nativeTokenPercentage) external onlyOwner() {
        _enableBuyback = _enabled;
        _buybackNativeTokenThreshold = nativeTokenThreshold;
        _buybackUpperLimit = upperLimit;
        _buybackNativeTokenPercentage = nativeTokenPercentage;
    }

    /**
     * @notice used to sets max amount for a single transaction
     */
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }

    /**
     * @notice used to sets max amount a wallet is allowed to hold
     */
    function setMaxHoldingPercent(uint256 maxHoldingPercent) external onlyOwner {
        _maxHoldingAllowed = _tTotal.mul(maxHoldingPercent).div(10**2);
    }

    /**
     * @notice used to set if liquidity is enabled
     */
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        _enableLiquidity = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /**
     * @notice used to pause transactions
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice used to unpause transactions
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice used to set threshold that contract tokens must be greater than before providing liquidity
     */
    function setTokenSwapThreshold(uint256 tokenSwapThreshold) external onlyOwner() {
        _tokenSwapThreshold = tokenSwapThreshold;
    }

    /**
     * @notice used to set marketing wallet address
     */
    function setMarketingAddress(bool _enabled, address marketingAddress) external onlyOwner() {
        _enableMarketingAddress = _enabled;
        _marketingAddress = payable(marketingAddress);
    }

    /**
     * @notice used to set development wallet address
     */
    function setDevelopmentAddress(bool _enabled, address developmentAddress) external onlyOwner() {
        _enableDevelopmentAddress = _enabled;
        _developmentAddress = payable(developmentAddress);
    }

    /**
     * @notice used to set charity wallet address
     */
    function setCharityAddress(bool _enabled, address charityAddress) external onlyOwner() {
        _enableCharityAddress = _enabled;
        _charityAddress = payable(charityAddress);
    }

    /**
     * @notice used to set product wallet address
     */
    function setProductAddress(bool _enabled, address productAddress) external onlyOwner() {
        _enableProductAddress = _enabled;
        _productAddress = payable(productAddress);
    }

    /**
     * @notice used to set if liquidity is enabled
     */
    function setLiquidity(bool isLiquidity) external onlyOwner() {
        _enableLiquidity = isLiquidity;
    }

    /**
     * @notice to recieve ETH from uniswapV2Router when swaping
     */
    receive() external payable {}

    /**
     * @notice used to deduct the necessary fees from the account
     */
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    /**
     * @return reflection amount, reflection amount after reflection fee deduction,
     *         reflection fee, token transfer amount after fees, tax fee, liquidity fee
     */
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    /**
     * @return the token transfer amount after fees, tax fee, liquidity fee for a given transfer amount
     */
    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    /**
     * @return the reflection amount, reflection amount after reflection fee deduction, reflection fee for a given transfer amount
     */
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    /**
     * @notice used to get the rate used to convert t-space tokens to r-space tokens and vice versa
     */
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /**
     * @notice get the current reflection and token supply
     */
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /**
     * @notice Collects liquidity tax
     */
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    /**
     * @notice calculates tax fee on a given amount
     */
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    /**
     * @notice calculates liquidity fee on a given amount
     */
    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    /**
     * @notice removes fees on the contract
     */
    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    /**
     * @notice restores fees on the contract
     */
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    /**
     * @notice checks if the address is excluded from the tax fee
     */
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
     * @notice approves a spender to send owners token
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Transfer to pair from non-router address is a sell swap
     */
    function _isSell(address sender, address recipient) internal view returns (bool) {
        return sender != address(uniswapV2Router) && recipient == address(uniswapV2Pair);
    }

    /**
     * @notice Transfer from pair is a buy swap
     */
    function _isBuy(address sender) internal view returns (bool) {
        return sender == address(uniswapV2Pair);
    }

    /**
     * @notice Internal transfer function used by transfer and transferFrom
     *         checks if contract has been paused
     *         checks if sender or recipient is blacklisted
     *         checks that recipient is not a whale
     *         checks that the transaction amount doesn't exceed the maximum allowed
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private whenNotPaused notBlacklisted(from) notBlacklisted(to) notCreatingAWhale(to) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner())
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        // Gets the contract token balance for buybacks, charity, liquidity and marketing
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        // AUTO-LIQUIDITY MECHANISM
        // Check that the contract token balance has reached the threshold required to execute a swap and liquify event
        bool overMinTokenBalance = contractTokenBalance >=
            _tokenSwapThreshold;

        // Check that liquidity feature is enabled
        // Do not execute the swap and liquify if there is already a swap happening
        // Do not allow the adding of liquidity if the sender is the Uniswap V2 liquidity pool
        if (
            _enableLiquidity &&
            overMinTokenBalance &&
            !currentlySwapping &&
            from != uniswapV2Pair
        ) {
            contractTokenBalance = _tokenSwapThreshold;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        // BUYBACK MECHANISM
        // If buyback is enabled, and someone is sending tokens to the liquidity pool (i.e. a sell), then we buy back tokens.
        // Do not execute the buyback if there is already a swap happening
        if (_enableBuyback && !currentlySwapping && _isSell(from, to)) {
	        uint256 balance = address(this).balance;

	        // Only execute a buyback when the contract has more than _buybackNativeTokenThreshold
            if (balance > _buybackNativeTokenThreshold) {
                if (balance >= _buybackUpperLimit) {
                    balance = _buybackUpperLimit;
                }

                // Buy back tokens with % of the Native token inside the contract
                buyBackTokens(balance.mul(_buybackNativeTokenPercentage).div(100));
            }
        }

        //indicates if fee should be deducted from transfer
        //if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);

        if (takeFee && _enableSellTaxFee && _isSell(from, to)) {
            _previousTaxFee = _taxFee;
            _taxFee = _sellTaxFee;
        }
        if (takeFee && _enableBuyTaxFee && _isBuy(from)) {
            _previousTaxFee = _taxFee;
            _taxFee = _buyTaxFee;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

        if (takeFee && _enableSellTaxFee && _isSell(from, to)) {
            _taxFee = _previousTaxFee;
        }

        if (takeFee && _enableBuyTaxFee && _isBuy(from)) {
            _taxFee = _previousTaxFee;
        }
    }

    /**
     * @notice Buys tokens using the contract balance
     */
    function buyBackTokens(uint256 amount) private lockTheSwap {
    	if (amount > 0) {
    	    swapNativeTokenForTokens(amount);
	    }
    }

    /**
     * @notice Swaps Native Token for tokens and immedietely burns them
     */
    function swapNativeTokenForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // Accept any amount of Token
            path,
            _burnAddress, // Burn address
            block.timestamp.add(300)
        );
    }

    /**
     * @notice Swaps Token for Native token and adds liquidity to uniswap
     */
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // Split the contract balance into the swap portion and the liquidity portion
        uint256 sixth = contractTokenBalance.div(6); // 1/6 of the tokens, used for liquidity
        uint256 swapAmount = contractTokenBalance.sub(sixth); // 5/6 of the tokens, used to swap for Native Currency

        // capture the contract's current balance.
        // this is so that we can capture exactly the amount of Native token that the
        // swap creates, and not make the liquidity event include any Native Token that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap 5/6 tokens for Native Token
        swapTokensForNativeToken(swapAmount);

        // how much Native token we just swapped into?
        uint256 recievedTokens = address(this).balance.sub(initialBalance);

        uint256 liquidityTokens = recievedTokens.div(5);

        // add liquidity to uniswap
        addLiquidity(sixth, liquidityTokens);

        if (_enableMarketingAddress){
            transferNativeTokenToAddress(_marketingAddress, liquidityTokens);
        }
        if (_enableCharityAddress){
            transferNativeTokenToAddress(_charityAddress, liquidityTokens);
        }
        if (_enableProductAddress){
            transferNativeTokenToAddress(_productAddress, liquidityTokens);
        }
        if (_enableDevelopmentAddress){
            transferNativeTokenToAddress(_developmentAddress, liquidityTokens);
        }
        emit SwapAndLiquify(swapAmount, recievedTokens, sixth);
    }

    /**
     * @notice swaps token for Native Token
     */
    function swapTokensForNativeToken(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Native Token
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @notice adds liquidity to uniswap
     */
    function addLiquidity(uint256 tokenAmount, uint256 nativeTokenAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: nativeTokenAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    /**
     * @notice private function to transfer tokens between different accounts
     */
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    /**
     * @notice a transfer when sender and recipient are not excluded from rewards
     */
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @notice transfer when recipient is excluded from rewards
     */
    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @notice transfer when sender is excluded from rewards
     */
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @notice transfer when both sender and recipient are excluded from rewards
     */
    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    /**
     * @notice adds ERC20 liquidity to cross-chain bridge (www.crosschainbridge.org)
     *
     * for more info about this bridge please go to https://docs.crosschainbridge.org/cross-chain-bridge/
     */
    function addERC20LiquidityToCrossChainBridge(
        uint256 amount
    ) external {        // TODO: should this function be external or internal? onlyOwner or public?

        // make sure that liquidity manager is excluded from fee, otherwise transaction will fail
        // TODO: check if this is correct
        require(_isExcludedFromFee[address(ccbLiquidityManager)], "Token: exclude CCB liquidity manager from fee first");

        // increase allowance for ccb liquidity manager to pull ERC20 tokens from caller's address
        increaseAllowance(address(ccbLiquidityManager), amount);

        // add ERC20 _liquidity to cross-chain bridge
        ccbLiquidityManager.addLiquidityERC20(IERC20(address(this)), amount);

        // TODO: NOTICE TO DEV TEAM
        // - once the step above is done, liquidity is added to the bridge
        // - could consider to throw an event here
        // - could consider add the LP tokens to the liquidity mining pool to earn passive income from bridging fees
    }

    /**
     * @notice withdraws ERC20 liquidity from cross-chain bridge (www.crosschainbridge.org)
     *
     * for more info about this bridge please go to https://docs.crosschainbridge.org/cross-chain-bridge/
     */
    function withdrawERC20LiquidityFromCrossChainBridge(
        uint256 amount
    ) external {        // TODO: should this function be external or internal? onlyOwner or public?
        // withdraw ERC20 _liquidity from cross-chain bridge
        ccbLiquidityManager.withdrawLiquidityERC20(IERC20(address(this)), amount);

        // TODO: NOTICE TO DEV TEAM
        // - could consider to throw an event here
    }

    /**
     * @notice stakes liquidity provider (LP) tokens in cross-chain bridge liquidity manager to earn passive income
     *         from bridging fees
     *
     * for more info about this bridge please go to https://docs.crosschainbridge.org/cross-chain-bridge/
     */
    function stakeLpTokensInCCBLiquidityMiningPools(
        uint256 amount
    ) external {        // TODO: should this function be external or internal? onlyOwner or public?

        // get LP token address for this token
        (bool exists, IERC20 lpToken) = ccbLiquidityManager.lpTokens(address(this));
        require(exists, "Token: add liquidity to liquidity manager first to create an LP token ");

        // approve LiquidityMiningPools contract to pull lp token
        //TODO: some tokens revert when adding approval on existing approval. We could consider to use SafeERC20 here (but costs gas)?
        lpToken.approve(address(ccbLiquidityMiningPools), 0);
        lpToken.approve(address(ccbLiquidityMiningPools), amount);

        // stake LP token in LiquidityMiningPools contract
        ccbLiquidityMiningPools.stake(address(this), amount);

        // TODO: NOTICE TO DEV TEAM
        // - could consider to throw an event here
    }

    /**
 * @notice withdraws ERC20 liquidity from cross-chain bridge (www.crosschainbridge.org)
 *
 * for more info about this bridge please go to https://docs.crosschainbridge.org/cross-chain-bridge/
 */
    function unstakeLPTokensFromCCBLiquidityMiningPools(
        uint256 amount
    ) external {        // TODO: should this function be external or internal? onlyOwner or public?
        // withdraw ERC20 _liquidity from cross-chain bridge
        ccbLiquidityMiningPools.unstake(address(this), amount);

        // TODO: NOTICE TO DEV TEAM
        // - could consider to throw an event here
    }

    /**
     * @notice harvests rewards earned from cross-chain bridge fees (www.crosschainbridge.org)
     *
     * for more info about this bridge please go to https://docs.crosschainbridge.org/cross-chain-bridge/
     */
    function harvestRewardsFromCCBLiquidityMiningPools(
    ) external {        // TODO: should this function be external or internal? onlyOwner or public?
        // withdraw ERC20 _liquidity from cross-chain bridge
        ccbLiquidityMiningPools.harvest(address(this), _msgSender());

        // TODO: NOTICE TO DEV TEAM
        // - could consider to throw an event here
    }
}


