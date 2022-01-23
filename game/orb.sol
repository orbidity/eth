// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./safe_math.sol";

interface ERC20_interface {
    function totalSupply() external view returns (uint);

    function balanceOf(address token_owner) external view returns (uint balance);
    function allowance(address token_owner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function transfer_to_escrow(address from, uint tokens) external;
    function transfer_from_escrow(address to, uint tokens) external;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed token_owner, address indexed spender, uint tokens);
}
 
//Contract function to receive approval and execute function in one call
 
interface Approve_and_call_fall_back {
    function receive_approval(address from, uint256 tokens, address token, bytes memory data) external;
}
 
contract Orb is ERC20_interface {
    using Safe_math for *;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _total_supply;
    address owner;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // mapping(uint => Game) games;
 
    constructor() {
        symbol = "ORB";
        name = "Orbs";
        decimals = 2;
        _total_supply = 0;
        owner = msg.sender;

        // Deprecated: 
        // _totalSupply = 100000000; // this is wrong, we mint new orbs on demand
        // balances[0x9E936b88C4faf32774306974a909852Dab3B6916] = _totalSupply;
        // emit Transfer(address(0), 0x9E936b88C4faf32774306974a909852Dab3B6916, _totalSupply);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function totalSupply() public override view returns (uint) {
        return _total_supply  - balances[address(0)];
    }
 
    function balanceOf(address token_owner) public override view returns (uint balance) {
        return balances[token_owner];
    }

    function giveMeOrbs(uint tokens) public returns (bool success) {
        require(tokens > 0);
        
        _total_supply = _total_supply.safe_add(tokens);
        balances[msg.sender] = balances[msg.sender].safe_add(tokens);
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }
 
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].safe_sub(tokens);
        balances[to] = balances[to].safe_add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = balances[from].safe_sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].safe_sub(tokens);
        balances[to] = balances[to].safe_add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        Approve_and_call_fall_back(spender).receive_approval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transfer_to_escrow(address from, uint tokens) public onlyOwner override {
        balances[from] = balances[from].safe_sub(tokens);
        emit Transfer(from, address(0x0), tokens);
    }

    function transfer_from_escrow(address to, uint tokens) public onlyOwner override {
        balances[to] = balances[to].safe_add(tokens);
        emit Transfer(address(0x0), to, tokens);

    }
}
