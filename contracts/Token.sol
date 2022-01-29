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
    // total r-space supply (reflections) which is between (MAX - _tTotal) and MAX
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
        address _router
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

        // set uniswap router contract
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

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

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    //Withdraws Native token from the contract
    function withdrawNative(uint256 amount) public onlyOwner() {
        if(amount == 0) payable(owner()).transfer(address(this).balance);
        else payable(owner()).transfer(amount);
    }

    // Transfers Native token to an address
    function transferNativeTokenToAddress(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    // get gross or net reflection amount when given a transfer amount
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

    // get token amount when given a reflection amount
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

    // exclude address from rewards
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    // include excluded account in rewards
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

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    function addToBlacklist(address account) external onlyOwner {
        _isBlacklisted[account] = true;
    }

    function removeFromBlacklist(address account) external onlyOwner {
        _isBlacklisted[account] = false;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setBuyTaxFeeAndPercent(bool _enabled, uint256 taxFee) external onlyOwner {
        _enableBuyTaxFee = _enabled;
        _buyTaxFee = taxFee;
    }

    function setSellTaxFeeAndPercent(bool _enabled, uint256 taxFee) external onlyOwner {
        _enableSellTaxFee = _enabled;
        _sellTaxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setBuybackEnabled(bool _enabled) external onlyOwner() {
        _enableBuyback = _enabled;
    }

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

    // sets max amount for a single transaction
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }

    // set max amount a wallet is allowed to hold
    function setMaxHoldingPercent(uint256 maxHoldingPercent) external onlyOwner {
        _maxHoldingAllowed = _tTotal.mul(maxHoldingPercent).div(10**2);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        _enableLiquidity = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setTokenSwapThreshold(uint256 tokenSwapThreshold) external onlyOwner() {
        _tokenSwapThreshold = tokenSwapThreshold;
    }

    function setMarketingAddress(bool _enabled, address marketingAddress) external onlyOwner() {
        _enableMarketingAddress = _enabled;
        _marketingAddress = payable(marketingAddress);
    }

    function setDevelopmentAddress(bool _enabled, address developmentAddress) external onlyOwner() {
        _enableDevelopmentAddress = _enabled;
        _developmentAddress = payable(developmentAddress);
    }

    function setCharityAddress(bool _enabled, address charityAddress) external onlyOwner() {
        _enableCharityAddress = _enabled;
        _charityAddress = payable(charityAddress);
    }

    function setProductAddress(bool _enabled, address productAddress) external onlyOwner() {
        _enableProductAddress = _enabled;
        _productAddress = payable(productAddress);
    }

    function setLiquidity(bool isLiquidity) external onlyOwner() {
        _enableLiquidity = isLiquidity;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    // returns reflection amount, reflection amount after reflection fee deduction, reflection fee, token transfer amount after fees, tax fee, liquidity fee
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

    // returns the token transfer amount after fees, tax fee, liquidity fee for a given transfer amount
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

    // returns the reflection amount, reflection amount after reflection fee deduction, reflection fee for a given transfer amount
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

    // gets the rate used to convert t-space tokens to r-space tokens and vice versa
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    // get the current reflection and token supply
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

    // adds liquidity
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

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

    // Transfer to pair from non-router address is a sell swap
    function _isSell(address sender, address recipient) internal view returns (bool) {
        return sender != address(uniswapV2Router) && recipient == address(uniswapV2Pair);
    }

    // Transfer from pair is a buy swap
    function _isBuy(address sender) internal view returns (bool) {
        return sender == address(uniswapV2Pair);
    }

    // internal transfer function used by transfer and transferFrom
    // checks if contract has been paused
    // checks if sender or recipient is blacklisted
    // checks that recipient is not a whale
    // checks that the transaction amount doesn't exceed the maximum allowed
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

    // Buys tokens using the contract balance
    function buyBackTokens(uint256 amount) private lockTheSwap {
    	if (amount > 0) {
    	    swapNativeTokenForTokens(amount);
	    }
    }

    // Swaps Native Token for tokens and immedietely burns them
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

    //this method is responsible for taking all fee, if takeFee is true
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

    // a transfer when sender and recipient are not excluded from rewards
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

    // transfer when recipient is excluded from rewards
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

    // transfer when sender is excluded from rewards
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

    // transfer when both sender and recipient are excluded from rewards
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
}
