// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint;

    string private name_;
    string private symbol_;
    uint8 private decimals_ = 18;
    uint  internal totalSupply_;

    mapping(address => uint) internal balanceOf_;                             //default internal
    mapping(address => mapping(address => uint)) internal allowance_;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public override constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    constructor(string memory _name , string memory _symbol) {
        name_ = _name;
        symbol_ = _symbol;
        uint chainId;

        assembly {
            chainId := chainId
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name_)),
                keccak256(bytes('1')),
                chainId,
                address(this)
                )
            );
    }

    function name() external view override returns (string memory) {
        return name_;
    }
    function symbol() external view override returns (string memory) {
        return symbol_;
    }
    function decimals() external view override returns (uint8) {
        return decimals_;
    }
    function totalSupply() external view override returns (uint) {
        return totalSupply_;
    }
    function balanceOf(address owner) external view override returns (uint) {
        return balanceOf_[owner];
    }
    function allowance(address owner, address spender) external view override returns (uint) {
        return allowance_[owner][spender];
    }

    function _mint(address _to , uint _value) internal {
        require(_to != address(0) , "ERC20:Cannot mint to NULL address");
        require(_value > 0 , "ERC20:Improper mint value");
        totalSupply_.add(_value);
        balanceOf_[_to].add(_value);
    }

    function _burn(address _from , uint _value) internal {
        require(_from != address(0) , "ERC20:Cannot Burn from NULL address");
        require(_value > 0 , "ERC20:Improper burn value");
        totalSupply_.sub(_value);
        balanceOf_[_from].sub(_value);
    }

    function _approve(address _owner , address _spender , uint _value) private {
        allowance_[_owner][_spender] = _value;
        emit Approval(_owner , _spender , _value);
    }

    function _transfer(address from , address to , uint value) internal {
        balanceOf_[from].sub(value);
        balanceOf_[to].add(value);
        emit Transfer(from , to , value);
    }

    function transfer(address to , uint value) external override returns (bool) {
        _transfer(msg.sender , to , value);
        return true;
    }

    function transferFrom(address from , address to , uint value) external override returns (bool) {
        require(allowance_[from][msg.sender] >= 0 , "ERC20:Not authorised for tranfer");
        _transfer(from , to , value);
        return true;
    }

    function approve(address _to , uint _value) external override returns(bool){
        _approve(msg.sender , _to , _value);
        return true;
    }

    /*
    By the permit function we can break the previous method of approve + transferFrom by making meta-transaction
    We sign and approve transaction off-chain and then the relayer makes an approve call 
    to the contract through the permit function.
    */


    function permit(address owner , address spender , uint value ,  uint deadline , 
    uint8 v , bytes32 r ,  bytes32 s) external override {
        require(deadline >= block.timestamp , "ERC20: Permit Signature expired");
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address signer = ecrecover(digest , v , r , s);    
        require(signer != address(0) && signer == owner , "ERC20:Permit Signature invalid");
        _approve(owner, spender, value);                    
    }
}

//https://github.com/t4sk/hello-erc20-permit
//can also use GSN for meta-transactions