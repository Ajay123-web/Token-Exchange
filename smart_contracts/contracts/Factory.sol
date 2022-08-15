// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IUniswapV2Factory.sol";
import "./V2Pair.sol";

contract Factory is IUniswapV2Factory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint) { return allPairs.length; }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB , "UniswapV2: IDENTICAL_ADDRESSES");
        //to calculate the address of Pair contract offchain we need it be sorted (layer2-scaling)
        (address token0 , address token1) = tokenA < tokenB ? (tokenA , tokenB) : (tokenB , tokenA);
        require(token0 != address(0) , "UniswapV2: ZERO_ADDRESS"); //if this is not zero then the other also cannot be zero
        require(getPair[token0][token1] == address(0) , "UniswapV2: PAIR_EXISTS"); //to make more stable pools
        //we create the contract this way instead of using <new> operator because we want a deterministic address
        bytes memory bytecode = type(V2Pair).creationCode;  //code that creates a contract
        bytes32 salt_ = keccak256(abi.encodePacked(token0 , token1));
        V2Pair pair_ = new V2Pair{salt: salt_}();
        pair = address(pair_);
        IUniswapV2Pair(pair).initialize(token0 , token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0 , token1 , pair , allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter , "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}