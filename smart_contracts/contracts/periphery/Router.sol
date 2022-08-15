// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IWETH.sol";

contract Router is IUniswapV2Router {
    using SafeMath for uint;
    address public immutable override factory;
    address public immutable override WETH;
    
    constructor(address _factory , address _WETH) { 
        factory = _factory;
        WETH = _WETH;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp , "UniswapV2Router: EXPIRED");
        _;
    }
    //receive executed when msg.data is empty and is used as a fallback to receive ether
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function _addLiquidity(address tokenA , address tokenB , 
        uint amountADesired , uint amountBDesired , 
        uint amountAMin , uint amountBMin
    ) internal returns(uint amountA , uint amountB) {

        if(IUniswapV2Factory(factory).getPair(tokenA , tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA , tokenB);
        }

        (uint reserveA , uint reserveB , ) =  IUniswapV2Pair(IUniswapV2Factory(factory).getPair(tokenA , tokenB)).getReserves();

        if(reserveA == 0 && reserveB == 0) {
            (amountA , amountB) = (amountADesired , amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired , reserveA , reserveB);
            if(amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin , "UniswapV2Router: INSUFFICIENT_B_AMOUNT");
                (amountA , amountB) = (amountADesired , amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired , reserveB , reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin , "UniswapV2Router: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal , amountBDesired);
            }
        }

    }

    function addLiquidity(address tokenA , address tokenB , 
        uint amountADesired , uint amountBDesired , 
        uint amountAMin , uint amountBMin , 
        address to , uint deadline
    ) external override ensure(deadline) returns(uint amountA , uint amountB , uint liquidity) {
        (amountA , amountB) = _addLiquidity(tokenA , tokenB , amountADesired , amountBDesired , amountAMin , amountBMin);
        address pair = IUniswapV2Factory(factory).getPair(tokenA , tokenB);
        TransferHelper.safeTransferFrom(tokenA , msg.sender , pair , amountA);
        TransferHelper.safeTransferFrom(tokenB , msg.sender , pair , amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function addLiquidityETH(address token , 
        uint amountTokenDesired ,  
        uint amountTokenMin ,  uint amountETHMin , 
        address to , uint deadline
    ) external override payable ensure(deadline) returns(uint amountToken , uint amountETH , uint liquidity) {
        (amountToken , amountETH) = _addLiquidity(token , WETH , amountTokenDesired , msg.value , amountTokenMin , amountETHMin);
        address pair = IUniswapV2Factory(factory).getPair(token , WETH);
        TransferHelper.safeTransferFrom(token , msg.sender , pair , amountToken);
        IWETH(WETH).deposit{value : amountETH}();
        assert(IWETH(WETH).transfer(pair , amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        if((msg.value - amountETH) > 0) { TransferHelper.safeTransferETH(msg.sender , msg.value - amountETH); }
    }
    /*
        -> get pair contract
        -> transfer LP token to contract
        -> Burn LP token
        -> Get amount of each to be payed back
        -> sort tokens
        -> check if the transaction is legitmate
    */

    function removeLiquidity(address tokenA , address tokenB , 
        uint liquidity , 
        uint amountAMin , uint amountBMin , 
        address to , 
        uint deadline
    ) public override ensure(deadline) returns(uint amountA , uint amountB) {

        address pair = IUniswapV2Factory(factory).getPair(tokenA , tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender , pair , liquidity);
        (uint amount0 , uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0 , ) = UniswapV2Library.sortTokens(tokenA , tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0 , amount1) : (amount1 , amount0);
        require(amountA >= amountAMin, "UniswapV2Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "UniswapV2Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(address token , 
        uint liquidity , 
        uint amountTokenMin , uint amountETHMin , 
        address to , 
        uint deadline
    ) public override ensure(deadline) returns (uint amountToken , uint amountETH) {
        (amountToken , amountETH) = removeLiquidity(token , WETH , liquidity , 
        amountTokenMin , amountETHMin , address(this) , deadline);        //transfer tokens to this contract itself
        TransferHelper.safeTransfer(token , to , amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to , amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA , address tokenB,
        uint liquidity ,
        uint amountAMin , uint amountBMin ,
        address to ,
        uint deadline ,
        bool approveMax , uint8 v , bytes32 r , bytes32 s
    ) external override returns (uint amountA , uint amountB) {
        address pair = UniswapV2Library.pairFor(factory , tokenA , tokenB);
        //uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender , address(this) , liquidity , deadline , v , r , s);
        (amountA , amountB) = removeLiquidity(tokenA , tokenB , liquidity , amountAMin , amountBMin , to , deadline);
    }

    function removeLiquidityETHWithPermit(
        address token ,
        uint liquidity ,
        uint amountTokenMin , uint amountETHMin,
        address to ,
        uint deadline ,
        bool approveMax , uint8 v , bytes32 r , bytes32 s
    ) external override returns (uint amountToken , uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory , token , WETH);
        IUniswapV2Pair(pair).permit(msg.sender , address(this) , liquidity , deadline , v , r , s);
        (amountToken , amountETH) = removeLiquidityETH(token , liquidity , amountTokenMin , amountETHMin , to , deadline);
    }

    function _swap(uint[] memory amounts , address[] memory path , address _to) internal {
        for(uint i = 0; i < path.length - 1; i++) {
            (address input , address output) = (path[i] , path[i + 1]);
            (address token0 , ) = UniswapV2Library.sortTokens(input , output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out , uint amount1Out) = token0 == input ? (amountOut , uint(0)) : (uint(0) , amountOut);
            address to = i < path.length - 2 ? IUniswapV2Factory(factory).getPair(output , path[i + 2]) : _to;
            IUniswapV2Pair(IUniswapV2Factory(factory).getPair(input , output)).swap(
                amount0Out , amount1Out , to , new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint amountIn , uint amountOutMin ,
        address[] calldata path ,  
        address to , 
        uint deadline
    ) external override ensure(deadline) returns(uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory , amountIn , path);
        require(amounts[amounts.length - 1] >= amountOutMin , "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0] , msg.sender , UniswapV2Library.pairFor(factory , path[0] , path[1]) , amountIn);
        _swap(amounts , path , to);
    }

    function getOutAmount(uint amountIn , address[] calldata path) external view returns(uint amount) {
        uint[] memory amounts = UniswapV2Library.getAmountsOut(factory , amountIn , path);
        amount = amounts[amounts.length - 1];
    }

    function swapTokensForExactTokens(
        uint amountOut ,
        uint amountInMax ,
        address[] calldata path ,
        address to ,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory , amountOut , path);
        require(amounts[0] <= amountInMax , "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0] , msg.sender , UniswapV2Library.pairFor(factory , path[0] , path[1]) , amounts[0]
        );
        _swap(amounts , path , to);
    }

    function swapExactETHForTokens(uint amountOutMin , address[] calldata path , address to , uint deadline) external
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH , "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsOut(factory , msg.value , path);
        require(amounts[amounts.length - 1] >= amountOutMin , "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory , path[0] , path[1]) , amounts[0]));
        _swap(amounts , path , to);
    }
    function swapTokensForExactETH(uint amountOut , uint amountInMax , address[] calldata path , address to , uint deadline)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH , "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsIn(factory , amountOut , path);
        require(amounts[0] <= amountInMax , "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0] , msg.sender , UniswapV2Library.pairFor(factory , path[0] , path[1]) , amounts[0]
        );
        _swap(amounts , path , address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to , amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn , uint amountOutMin , address[] calldata path , address to , uint deadline)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH , "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsOut(factory , amountIn , path);
        require(amounts[amounts.length - 1] >= amountOutMin , "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0] , msg.sender , UniswapV2Library.pairFor(factory , path[0] , path[1]) , amounts[0]
        );
        _swap(amounts , path , address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to , amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut , address[] calldata path , address to , uint deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH , "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsIn(factory , amountOut , path);
        require(amounts[0] <= msg.value , "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory , path[0] , path[1]) , amounts[0]));
        _swap(amounts , path , to);
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender , msg.value - amounts[0]);
    }

        function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    //Library functions for external use
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

}