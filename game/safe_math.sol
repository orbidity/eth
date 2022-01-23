// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
 
library Safe_math {
 
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
}