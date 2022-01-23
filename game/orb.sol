// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Tic_tac_toe} from "./tic_tac_toe.sol";
import {Blackjack} from "./blackjack.sol";

enum Game_type { Null, Tic_tac_toe, Blackjack }

struct Player {
    address player_address;
    address player_strategy;
}

struct Game {
    Player[] players;
    uint size;
    uint256 stake;
    Game_type game_type;
}

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
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _total_supply;
    address owner;
 
    Blackjack public blackjack;
    Tic_tac_toe public tic_tac_toe;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // mapping(uint => Game) games;
 
    constructor() {
        symbol = "ORB";
        name = "Orbs";
        decimals = 2;
        _total_supply = 0;
        owner = msg.sender;

        blackjack = new Blackjack();
        tic_tac_toe = new Tic_tac_toe();

        // Deprecated: 
        // _totalSupply = 100000000; // this is wrong, we mint new orbs on demand
        // balances[0x9E936b88C4faf32774306974a909852Dab3B6916] = _totalSupply;
        // emit Transfer(address(0), 0x9E936b88C4faf32774306974a909852Dab3B6916, _totalSupply);
    }

    function safe_add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "safe_add failed");
    }
 
    function safe_sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "safe_sub failed");
        c = a - b;
    }
 
    function safe_mul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "safe_mul failed");
    }
 
    function safe_div(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "safe_div failed");
        c = a / b;
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
        
        _total_supply = safe_add(_total_supply, tokens);
        balances[msg.sender] = safe_add(balances[msg.sender], tokens);
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }
 
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safe_sub(balances[msg.sender], tokens);
        balances[to] = safe_add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safe_sub(balances[from], tokens);
        allowed[from][msg.sender] = safe_sub(allowed[from][msg.sender], tokens);
        balances[to] = safe_add(balances[to], tokens);
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

    function transfer_to_escrow(address from, uint tokens) public override {
        balances[from] = safe_sub(balances[from], tokens);
        emit Transfer(from, address(0x0), tokens);
    }

    function transfer_from_escrow(address to, uint tokens) public override {
        balances[to] = safe_add(balances[to], tokens);
        emit Transfer(address(0x0), to, tokens);

    }


    ///// orb

    event Game_result(uint id, address winner);
    event Game_draw();
    uint id = 0;

    mapping (uint => Game) games;

    function is_valid_size(uint _size, Game_type _game_type) private pure returns (bool) {
        require(_game_type != Game_type.Null); // unreachable

        if (_game_type == Game_type.Tic_tac_toe) {
            // Tic tac toe
            return _size == 2;
        } else {
            // Blackjack
            return _size >= 2;
        }
    }

    function create(uint _stake, uint _size, Game_type _game_type) public returns (uint) {
        Game storage game = games[id];

        // Set game type
        require(_game_type != Game_type.Null, "Game type cannot be Null.");
        game.game_type = _game_type;

        // Set stake
        // require(_stake > 0, "Stake must be greater than zero.");
        game.stake = _stake;

        // Set size
        require(is_valid_size(_size, _game_type), "Size of game is invalid.");        
        game.size = _size;

        // Return id of game, incrementing id.
        return id++;
    }

    function is_valid_game(uint _id) private view returns (bool) {
        Game storage game = games[_id];
        return (game.game_type != Game_type.Null && is_valid_size(game.size, game.game_type));
    }

    function play(uint _id) private returns (uint) {
        Game storage game = games[_id];

        address[] memory strategies = new address[](game.size);
        for (uint i = 0; i < game.size; i++) {
            strategies[i] = game.players[i].player_strategy;
        }

        if (game.game_type == Game_type.Tic_tac_toe) {
            return tic_tac_toe.play(strategies);
        } else {
            return blackjack.play(strategies);
        }
    }

    function join(uint _id, address _strategy) public {
        require(is_valid_game(_id), "Cannot join invalid game!");

        Game storage game = games[_id];

        // Add player
        game.players.push(Player(msg.sender, _strategy));

        // Transaction to Escrow
        transfer_to_escrow(msg.sender, game.stake);

        // If we reach required number of players, automatically play
        if (game.players.length == game.size) {

            uint _winner = play(_id);            
            if (_winner == type(uint).max) {
                emit Game_draw ();

                // Transaction form Escrow
                for (uint i = 0; i < game.size; i++) {
                    transfer_from_escrow(game.players[i].player_address, game.stake);
                }
            } else {
                address _winner_address = game.players[_winner].player_address;
                emit Game_result(_id, _winner_address);
   
                // Transaction from Escrow
                transfer_from_escrow(_winner_address, game.stake * game.size);
            }

            // Free storage resources
            delete games[_id];
        }
    }

    function cancel(uint _id) public {
        require(is_valid_game(_id), "Cannot cancel invalid game!");

        Game storage game = games[_id];
        for (uint i = 0; i < game.size; i++) {
            transfer_from_escrow(game.players[i].player_address, game.stake);
        }

        // Free storage resources
        delete games[_id];
    }

}
