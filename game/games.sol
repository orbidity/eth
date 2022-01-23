// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Orb} from "./orb.sol";
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
 

contract Games {
    Orb public orb;
    Blackjack public blackjack;
    Tic_tac_toe public tic_tac_toe;

    event Game_result(uint id, address winner);
    event Game_draw();

    uint id = 0;

    constructor () public {
        // Initialize other contracts. 

        orb = new Orb();
        blackjack = new Blackjack();
        tic_tac_toe = new Tic_tac_toe();
    }

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
        require(_stake > 0, "Stake must be greater than zero.");
        game.stake = _stake;

        // Set size
        require(is_valid_size(_size, _game_type), "Size of game is invalid.");        
        game.size = _size;

        // Return id of game, incrementing id.
        return id++;
    }

    function is_valid_game(uint _id) private view returns (bool) {
        Game storage game = games[_id];
        return (game.stake > 0 && game.game_type != Game_type.Null && is_valid_size(game.size, game.game_type));
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
        orb.transfer_to_escrow(msg.sender, game.stake);

        // If we reach required number of players, automatically play
        if (game.players.length == game.size) {

            uint _winner = play(_id);            
            if (_winner == type(uint).max) {
                emit Game_draw ();

                // Transaction form Escrow
                for (uint i = 0; i < game.size; i++) {
                    orb.transfer_from_escrow(game.players[i].player_address, game.stake);
                }
            } else {
                address _winner_address = game.players[_winner].player_address;
                emit Game_result(_id, _winner_address);
   
                // Transaction from Escrow
                orb.transfer_from_escrow(_winner_address, game.stake * game.size);
            }

            // Free storage resources
            delete games[_id];
        }
    }

    function cancel(uint _id) public {
        require(is_valid_game(_id), "Cannot cancel invalid game!");

        Game storage game = games[_id];
        for (uint i = 0; i < game.size; i++) {
            orb.transfer_from_escrow(game.players[i].player_address, game.stake);
        }

        // Free storage resources
        delete games[_id];
    }

}





