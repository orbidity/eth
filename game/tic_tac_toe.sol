// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

enum Player { None, One, Two }

// Note: Internal depedence between the ordering of [Player] in [Strategy] 
// and [Game]. Since implicit coercion between uint and [Player] occurs during
// (de-)seralization.

interface Strategy {
    function get_move(Player[] memory) external pure returns (uint); 
}

abstract contract Game {
    // Addresses of the 2 [Strategy] smart contracts
    address player_1_strategy;
    address player_2_strategy;

    
    constructor(address _player_1_strategy, address _player_2_strategy) {
        player_1_strategy = _player_1_strategy;
        player_2_strategy = _player_2_strategy;
    }

    function play() public virtual returns (Player);
}


contract Tic_tac_toe is Game {

    constructor (address player_1_strategy, address player_2_strategy) public Game(player_1_strategy, player_2_strategy) {}


    // Turn determines which strategy is used
    uint turn = 1;
    Player[] board = new Player[](9); // 0 - 8 are positions
    Player winner = Player.None;

    function get_player() private view returns (Player) {
        if (turn % 2 == 1) { 
            return Player.One; 
        } else { 
            return Player.Two; 
        } 
    }

    function get_winner() private view returns (Player) {
        // Player wins if a line of 3 (row, column)
        for (uint i = 0; i < 3; i++) {
            // Check row
            if (board[i] == board[i + 1] && board[i + 1] == board[i + 2]) {
                return (board[i]);
            }

            if (board[i] == board[i + 3] && board[i + 3] == board[i + 6]) {
                return (board[i]);
            }
        }

        // Check diagonals
        if (board[0] == board[4] && board[4] == board[8]) {
            return (board[0]);
        }

        if (board[2] == board[4] && board[4] == board[6]) {
            return (board[2]);
        }

        return Player.None;
    }

    function is_valid_move(uint pos) private view returns (bool) {
        return (winner == Player.None && pos >= 0 && pos <= 8 && board[pos] == Player.None);
    } 

    function get_move(Player _player) private view returns (uint) {
        address _strategy = _player == Player.One ? player_1_strategy : player_2_strategy;
        return Strategy(address(_strategy)).get_move(board);
    }

    function draw() private view returns (bool) {
        // No empty spaces
        for (uint i = 0; i < 8; i++) {
            if (board[i] == Player.None) return false;
        }

        return true;
    }

    function play() public override returns (Player) {
        while (winner == Player.None && !draw()) {
            // Determine player
            Player _player = get_player();

            // Ask what the player would like to do via their strategy
            uint _pos = get_move(_player);
            require(is_valid_move(_pos));
            
            board[_pos] = _player;

            // Check winner
            Player _winner = get_winner();
            if (_winner != Player.None) {
                winner = _winner;
            }

            turn++;
        }

        return winner;
    }

    function get_board() public view returns (Player[] memory) {
        return board;
    }

}