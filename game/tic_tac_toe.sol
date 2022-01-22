// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./game.sol";

enum Player { None, One, Two }

interface Tic_tac_toe_strategy is Strategy {
    function get_move(Player[] memory) external returns (uint); 
}

contract Strategy_1 is Tic_tac_toe_strategy {
    function get_move(Player[] memory _board) external override pure returns (uint) {
        // Returns first free position
        for (uint i = 0; i < _board.length; i++) {
            if (_board[i] == Player.None) return i;
        }
        
        // Cannot reach here
        revert();
    }

}

contract Tic_tac_toe is Game {
    event State_event (Player[] board);

    function get_player(uint _turn) private pure returns (Player) {
        if (_turn % 2 == 1) { 
            return Player.One; 
        } else { 
            return Player.Two; 
        } 
    }


    function get_winner(Player[] memory _board) private pure returns (Player) {
        // Player wins if a line of 3 (row, column)
        for (uint i = 0; i < 3; i++) {
            // Check row
            if (_board[i] == _board[i + 1] && _board[i + 1] == _board[i + 2]) {
                return (_board[i]);
            }

            if (_board[i] == _board[i + 3] && _board[i + 3] == _board[i + 6]) {
                return (_board[i]);
            }
        }

        // Check diagonals
        if (_board[0] == _board[4] && _board[4] == _board[8]) {
            return (_board[0]);
        }

        if (_board[2] == _board[4] && _board[4] == _board[6]) {
            return (_board[2]);
        }

        return Player.None;
    }

    function is_valid_move(Player[] memory _board, uint pos) private pure returns (bool) {
        return (pos >= 0 && pos <= 8 && _board[pos] == Player.None);
    } 

    function get_move(address _strategy, Player[] memory _board) private returns (uint) {
        return Tic_tac_toe_strategy(address(_strategy)).get_move(_board);
    }

    function draw(Player[] memory _board) private pure returns (bool) {
        // No empty spaces
        for (uint i = 0; i < 8; i++) {
            if (_board[i] == Player.None) return false;
        }

        return true;
    }

    function convert_winner_to_int(Player _winner) private pure returns (uint) {
        if (_winner == Player.None) {
            return type(uint).max;
        } else if (_winner == Player.One) {
            return 0;
        } else {
            return 1;
        }
    }

    function play(address[] memory _players) public override returns (uint) {
        // Tic tac toe is only valid w/ 2 players
        require (_players.length == 2);

        address _player_1 = _players[0];
        address _player_2 = _players[1];

        // Turn determines which strategy to use
        uint _turn = 1;
        
        Player[] memory _board = new Player[](9); // 0 - 8 are positions
        Player _winner = Player.None;

        while (_winner == Player.None && !draw(_board)) {
            // Determine player
            Player _player = get_player(_turn);

            // Ask what the player would like to do via their strategy
            uint _pos = get_move(_player == Player.One ? _player_1 : _player_2, _board);
            require(is_valid_move(_board, _pos));
            
            _board[_pos] = _player;

            emit State_event (_board);

            // Check winner
            Player _pos_winner = get_winner(_board);
            if (_pos_winner != Player.None) {
                _winner = _pos_winner;
            }

            _turn++;
        }

        return convert_winner_to_int(_winner);

    }
}