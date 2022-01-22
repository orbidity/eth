// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./game.sol";

enum Action { Hit, Stop }

interface Blackjack_strategy is Strategy {
    function get_action(uint hand) external returns (Action); 
}


contract Strategy_1 is Blackjack_strategy {
    function get_action(uint _hand) external override pure returns (Action) {
        return Action.Stop;
    }
}

contract Strategy_2 is Blackjack_strategy {
    function get_action(uint hand) external override pure returns (Action) {
        if (hand < 21) {
            return Action.Hit;
        } else {
            return Action.Stop;
        }
    }
}

function random(uint256 seed, uint256 low, uint256 hi) pure returns (uint256, uint256) {
    uint256 a = 16807;
    uint256 m = 2147483647;
    seed = (a * seed) % m;
    return (seed, low + seed % (hi - low));
}

contract Blackjack is Game {
    event State_event (address indexed strategy, uint hand);
    event Action_event (address indexed strategy, uint hand, Action action);

    uint[13] card_value = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10]; 

    // Seed used for "randomness"
    uint seed = 1;

    struct Deck {
        uint[] deck_cards;
        uint deck_pos;
    }


    function hit(Deck memory _deck) private pure returns (uint) {
        uint _card = _deck.deck_cards[_deck.deck_pos];
        _deck.deck_pos++;

        return _card;
    }

    function deal(Deck memory _deck) private pure returns (uint) {
        uint _first_card = hit(_deck);
        uint _second_card = hit(_deck);

        return _first_card + _second_card;
    }
    
    
    function get_action(address _strategy, uint _hand) private returns (Action) {
        return Blackjack_strategy(address(_strategy)).get_action(_hand);
    }

    struct Player_state {
        uint hand;
        bool is_playing;
    }

    function play(address[] memory _players) public override returns (uint) {

        // Initialize
        Deck memory _deck = Deck(new uint[](52), 0); 
        for (uint i = 0; i < 4; i++) {
            for (uint j = 0; j < 13; j++) {
                _deck.deck_cards[i * 13 + j] = card_value[j];
            }
        }

        // Shuffle deck
        for (uint i = 0; i < 50; i++) {
            uint256 j;
            (seed, j) = random(seed, i, 52);
            
            uint temp = _deck.deck_cards[i];
            _deck.deck_cards[i] = _deck.deck_cards[uint(j)];
            _deck.deck_cards[uint(j)] = temp;
        }

        
        // Initialize states
        uint _remaining_players = _players.length;
        Player_state[] memory _player_states = new Player_state[](_players.length); 
        for (uint i = 0; i < _players.length; i++) {
            _player_states[i] = Player_state(deal(_deck), true);
        }

        // Emit the state
        for (uint i = 0; i < _players.length; i++) {
            emit State_event (_players[i], _player_states[i].hand);
        }

        // Play :)
        while (_remaining_players > 0) {
            for (uint i = 0; i < _players.length; i++) {
                if (_player_states[i].is_playing) {
                    Action _action = get_action(_players[i], _player_states[i].hand);
                    emit Action_event (_players[i], _player_states[i].hand, _action);
                    if (_action == Action.Hit) {
                        _player_states[i].hand += hit(_deck);
                    } else {
                        _player_states[i].is_playing = false;
                        _remaining_players--;
                    }
                }
            }
        }

        // Determine winner. Returns != -1 if a "unique" winner
    
        uint _winner = type(uint).max;
        for (uint i = 0; i < _players.length; i++) {
            if (_player_states[i].hand == 21) {
                if (_winner == (type(uint).max)) {
                    _winner = i;
                } else {
                    return type(uint).max;
                }
            }
        }

        return _winner;
    }

}