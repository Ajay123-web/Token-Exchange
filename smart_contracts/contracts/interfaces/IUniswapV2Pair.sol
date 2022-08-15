// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IUniswapV2Pair is IERC20 {
    event Mint(address indexed sender , uint amount0 , uint amount1); //Liquidity provided
    event Burn(address indexed sender , uint amount0 , uint amount1 , address indexed to); //Liquidity withdrawn
    event Swap(               //trader swap 
        address indexed sender,           //caller
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to                //trader address that actually gets and gives the token
    );

    event Sync(uint112 reserve0 , uint112 reserve1);       //provide latest reserve info

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}