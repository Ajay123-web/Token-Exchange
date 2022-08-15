// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IUniswapV2Factory.sol";
import "./libraries/SafeMath.sol";
import "./libraries/UQ112x112.sol";
import "./libraries/Math.sol";
import "./ERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract V2Pair is IUniswapV2Pair , ERC20{
    using SafeMath  for uint;
    using UQ112x112 for uint224; //for fractions (112 bits for integer part and the rest 112 for fraction part)

    uint private constant MINIMUM_LIQUIDITY_ = 10**3;  //min LP tokens belong to address 0
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)"))); //ABI selector for tranfer fun

    address private factory_;
    address private token0_;
    address private token1_;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimeStampLast; //timestamp of last block in which this trade occured

    uint private price0CumulativeLast_;     //cost of token ... helps in finding average cost in an interval
    uint private price1CumulativeLast_;

    uint private kLast_;       // exchange rate (const of AMM)

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1 , "UniswapV2:Locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function MINIMUM_LIQUIDITY() external pure override returns (uint) { return MINIMUM_LIQUIDITY_; }
    function factory() external view override returns (address) { return factory_; }
    function token0() external view override returns (address) { return token0_; }
    function token1() external view override returns (address) { return token1_; }
    function price0CumulativeLast() external view override returns (uint) { return price0CumulativeLast_; }
    function price1CumulativeLast() external view override returns (uint) { return price1CumulativeLast_; }
    function kLast() external view override returns (uint) { return kLast_; }

    function getReserves() public view override returns(uint112 , uint112 , uint32){
        return (reserve0 , reserve1 , blockTimeStampLast);
    }

    function _safeTransfer(address token , address to , uint value) private {
        //we can also do it by making an interface for ERC20 contract which include only transfer function 
        (bool success , bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR , to , value));
        require(success && (data.length == 0 || abi.decode(data , (bool))) , "UniswapV2: TRANSFER_FAILED"); //revert cond
    }   
    constructor() ERC20("Uniswap2.0" , "LP"){
        factory_ = msg.sender;
    }

    function initialize(address _token0 , address _token1) external override {
        token0_ = _token0;
        token1_ = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0 , uint balance1 , uint112 _reserve0 , uint112 _reserve1) private {
        require(balance0 < UQ112x112.Q112 && balance1 < UQ112x112.Q112 , "UniswapV2: OVERFLOW");
        uint32 blockTimeStamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimeStamp - blockTimeStampLast;
        if(timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            price0CumulativeLast_ += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast_ += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimeStampLast = blockTimeStamp;
        emit Sync(reserve0 , reserve1);
    }

    //if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0 , uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory_).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast_;
        if(feeOn) {
            if(_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast =  Math.sqrt(_kLast);
                if(rootK > rootKLast) {
                    uint numerator = totalSupply_.mul(rootK - rootKLast);
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if(liquidity > 0) _mint(feeTo , liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast_ = 0;
        }
    }

    function mint(address _to) external lock override returns (uint liquidity) {
        (uint112 _reserve0 , uint112 _reserve1 , ) = getReserves();
        uint balance0 = IERC20(token0_).balanceOf(address(this));      //periphery contract gives token0 to this contract before calling this function
        uint balance1 = IERC20(token1_).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);                        //amount of token0 added by liquidity provider
        uint amount1 = balance1.sub(_reserve1);
        bool feeOn = _mintFee(_reserve0 , _reserve1);
        uint _totalSupply = totalSupply_;     //totalSupply of LP tokens
        if(_totalSupply == 0) {    //liquidity provided for first time
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY_);
            _mint(address(0) , MINIMUM_LIQUIDITY_);
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0 , amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0 , "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED.");
        _mint(_to , liquidity);
        _update(balance0 , balance1 , _reserve0 , _reserve1);
        if (feeOn) kLast_ = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(_to , amount0 , amount1);
    }

    function burn(address to) external lock override returns (uint amount0 , uint amount1) {
        (uint112 _reserve0 , uint112 _reserve1 , ) = getReserves();
        uint _totalSupply = totalSupply_;
        address _token0 = token0_;
        address _token1 = token1_;
        bool feeOn = _mintFee(_reserve0 , _reserve1);
        uint liquidity = balanceOf_[address(this)];   //periphery contract transfer LP tokens to this contract

        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        amount0 = liquidity.mul(balance0) / _totalSupply;       //amount to be returned to the liquidity provider
        amount1 = liquidity.mul(balance1) / _totalSupply;

        require(amount0 > 0 && amount1 > 0 , "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED.");
        _burn(address(this) , liquidity);

        _safeTransfer(_token0 , to , amount0);
        _safeTransfer(_token1 , to , amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0 , balance1 , _reserve0 , _reserve1);
         if (feeOn) kLast_ = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender , amount0 , amount1 , to);
    }
    /*
    This function is also called by peiphery but before that appropriate amount for one of the tokens is transferred
    to this contract but we do not know which token was traded for which token.
    */
    function swap(uint amount0Out , uint amount1Out , address to , bytes calldata data) external override lock {
        require(amount0Out > 0 || amount1Out > 0 , "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0 , uint112 _reserve1 , ) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1 , "UniswapV2: INSUFFICIENT_LIQUIDITY");
        uint balance0;
        uint balance1;

        {
            address _token0 = token0_;
            address _token1 = token1_;
            require(to != _token0 && to != _token1 , "UniswapV2: INVALID_TRANSFER_ADDRESS");
            if(amount0Out > 0) _safeTransfer(_token0 , to , amount0Out); //tranfers token to be taken out of the pool to the trader
            if(amount1Out > 0) _safeTransfer(_token1 , to , amount1Out);
            if(data.length > 0) {
                //inform the trader about the transfer
            }
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        // this calculates the amount of token given in by the trader
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0 , "UniswapV2: INSUFFICIENT_INPUT_AMOUNT");

        {
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), "UniswapV2: K");
        }

        _update(balance0 , balance1 , _reserve0 , _reserve1);
        emit Swap(msg.sender , amount0In , amount1In , amount0Out , amount1Out , to);
    }   

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0_; 
        address _token1 = token1_; 
        _safeTransfer(_token0 , to , IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1 , to , IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(token0_).balanceOf(address(this)) , IERC20(token1_).balanceOf(address(this)) , reserve0 , reserve1);
    }

}