// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
 
//Safe Math Interface
 
contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "safeAdd failed");
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "safeSub failed");
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "safeMul failed");
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "safeDiv failed");
        c = a / b;
    }
}
 
 
//ERC Token Standard #20 Interface
 
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event GameResult(address indexed winner);
}
 
 
//Contract function to receive approval and execute function in one call
 
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}
 
//Actual token contract
enum GameType { NULL, TTT, BLACKJACK }

struct Player {
    address orbAddress;
    address strategyAddress;
}

struct Game {
    Player[] players;
    uint256 stake;
    GameType gameType;
}
 
contract ORBToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    mapping(uint => Game) games;
 
    constructor() {
        symbol = "ORB";
        name = "Orbs";
        decimals = 2;
        _totalSupply = 0;
        // _totalSupply = 100000000; // this is wrong, we mint new orbs on demand
        // balances[0x9E936b88C4faf32774306974a909852Dab3B6916] = _totalSupply;
        // emit Transfer(address(0), 0x9E936b88C4faf32774306974a909852Dab3B6916, _totalSupply);
    }
 
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function giveMeOrbs(uint tokens) public returns (bool success) {
        require(tokens > 0);
        _totalSupply = safeAdd(_totalSupply, tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }
 
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    ///////////////////////////
    // GAME INTEGRATION
    ///////////////////////////

    function joinGame(uint gameId, uint stake, address strategy, GameType gameType) public {
        Game storage game = games[gameId];

        uint N_PLAYERS = 2; // todo: dynamic

        require(stake > 0, "Stake must be greater than zero");

        if (game.stake > 0) {
            // Someone else has already staked
            require(stake == game.stake, "All players must have the same stake");
        } else {
            game.stake = stake;
        }

        if (game.gameType == GameType.NULL) {
            require(gameType != GameType.NULL, "Game type cannot be NULL");
            game.gameType = gameType;
        } else {
            require(gameType == game.gameType, "All players must be requesting the same game type");
        }

        require(game.players.length < N_PLAYERS, "Too many players"); // this should never happen

        game.players.push(Player(msg.sender, strategy));

        // Eat the tokens from this player
        balances[msg.sender] = safeSub(balances[msg.sender], stake);
        emit Transfer(msg.sender, address(0x0), stake);

        if (game.players.length == N_PLAYERS) {
            // We are ready to go!
            // TODO: Play the game
            uint winnerId = 0;
            address winnerAddress = game.players[winnerId].orbAddress;
            emit GameResult(winnerAddress);

            balances[winnerAddress] = safeAdd(balances[winnerAddress], stake * N_PLAYERS);
            emit Transfer(address(0x0), msg.sender, stake * N_PLAYERS);

            cancelGame(gameId);
        }
    }

    function getStake(uint gameId) public view returns (uint stake) {
        return games[gameId].stake;
    }

    function getGameType(uint gameId) public view returns (GameType gameType) {
        return games[gameId].gameType;
    }

    function cancelGame(uint gameId) public {
        // Cancels games for all players, returns money
        Game storage game = games[gameId];

        while (game.players.length > 0) {
            Player memory player = game.players[game.players.length - 1];
            balances[player.orbAddress] = safeAdd(balances[player.orbAddress], game.stake);
            emit Transfer(address(0x0), msg.sender, game.stake);
            game.players.pop();
        }
    }

}
