// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; //version of solidity

contract dappToken{
    string public name;
    string public symbol;
    string public standard = "Dapp Token v1.0";

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokens
    );

    event Approval(             //owner approves spender to spend value tokens
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor(uint256 _totalSupply , string memory _name , string memory _symbol){
        totalSupply = _totalSupply;
        name = _name;
        symbol = _symbol;
        //initial owner of all tokens
        balanceOf[msg.sender] = _totalSupply;

    }

    function transfer(address _to , uint256 _tokens) public returns(bool success){
        require(balanceOf[msg.sender] >= _tokens , "Not enough Tokens");

        balanceOf[msg.sender] -= _tokens;
        balanceOf[_to] += _tokens;

        emit Transfer(msg.sender , _to , _tokens);

        return true;
    }

    //approve
    function approve(address _spender , uint256 _value) public returns(bool success){
        allowance[msg.sender][_spender] = _value; 
        emit Approval(msg.sender , _spender , _value);

        return true;
    }

    //transferFrom
    function transferFrom(address _from , address _to , uint256 _value) public returns(bool success){
        require(balanceOf[_from] >= _value , "Not Enough Balance in the _from account.");
        require(allowance[_from][msg.sender] >= _value , "This much expenditure is not allowed");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from , _to , _value);
        return true;
    }
}