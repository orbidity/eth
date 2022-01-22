// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Each player has an address and a strategy (given by an address)
// struct Player {
//     address player_address;
//     address player_strategy;
// }

interface Game {
    // @dev: assumes the returned [uint] satisfies [0 <= player_index <= players.length - 1]
    // or [-1] is no winner. 
    function play(address[] memory) external returns (uint);
}

interface Strategy {}