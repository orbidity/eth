// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

enum Player { None, One, Two }
enum Action { Hit, Stop }


interface Strategy {
    function get_move(uint hand) external pure returns (Action); 
}

contract Blackjack {

    address player_1_strategy;
    address player_2_strategy;

    uint[13] card_value = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10];
    uint[52] deck;
    uint deck_pos;

    function random(uint256 seed, uint256 low, uint256 hi) private pure returns (uint256, uint256) {
        uint256 a = 16807;
        uint256 m = 2147483647;
        seed = (a * seed) % m;
        return (seed, low + seed % (low - hi));
    }

    constructor (address _player_1_strategy, address _player_2_strategy, uint256 seed) public {
        player_1_strategy = _player_1_strategy;
        player_2_strategy = _player_2_strategy;

        // Initialize deck
        deck_pos = 0;
        for (uint i = 0; i < 4; i++) {
            for (uint j = 0; i < 13; j++) {
                deck[i * 13 + j] = j;
            }
        }

        // Shuffle deck
        for (uint i = 0; i < 50; i++) {
            uint256 j;
            (seed, j) = random(seed, i, 52);
            
            uint _temp = deck[i];
            deck[i] = deck[uint(j)];
            deck[uint(j)] = _temp;
        }
    }

    function deal() private returns (uint) {
        uint _first_card = deck[deck_pos];
        deck_pos++;
        
        uint _second_card = deck[deck_pos];
        deck_pos++;

        return _first_card + _second_card;
    }

    function hit() private returns (uint) {
        uint _card = deck[deck_pos];
        deck_pos++;

        return _card;
    }

    enum State { Playing, Stopped }

    function get_move(Player _player, uint _hand) private view returns (Action) {
        address _strategy = _player == Player.One ? player_1_strategy : player_2_strategy;
        return Strategy(address(_strategy)).get_move(_hand);
    }

    function play() public returns (Player) {
        uint player_1_hand = deal();
        uint player_2_hand = deal();

        State player_1_state = State.Playing;
        State player_2_state = State.Playing;
        
        while (player_1_state == State.Playing || player_2_state == State.Playing) {
            if (player_1_state == State.Playing) {
                Action _action = get_move(Player.One, player_1_hand);
                if (_action == Action.Hit) {
                    player_1_hand += hit();
                } else {
                    player_1_state = State.Stopped;
                }
            }

            if (player_2_state == State.Playing) {
                Action _action = get_move(Player.Two, player_2_hand);
                if (_action == Action.Hit) {
                    player_2_hand += hit();
                } else {
                    player_2_state = State.Stopped;
                }
            }
        }

        if (player_1_hand == 21 && player_2_hand == 21) {
            return Player.None;
        }

        if (player_1_hand == 21) {
            return Player.One;
        }

        if (player_2_hand == 21) {
            return Player.Two;
        }

        return Player.None;
    }

}