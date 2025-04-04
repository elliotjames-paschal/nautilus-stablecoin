// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Oracle {

    uint256 constant HARD_CODED_PRICE = 333333333333333; 
    // mapping(address => uint256) public prices; // Stablecoin to price mapping

    // function setPrice(address stablecoin, uint256 price) external {
       // prices[stablecoin] = price;
    
    function getPrice(address) external pure returns (uint256) {
        return HARD_CODED_PRICE;
    }

    // function getPrice(address stablecoin) external view returns (uint256) {
        // Logic to fetch price using Chainlink or other oracles
        // return prices[stablecoin];
    
}