// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {TokenWithSanctions} from "../src/week1/TokenWithSanctions.sol";

contract Deploy is Script {
    
    function run() external returns (TokenWithSanctions) {
        TokenWithSanctions tokenWithSanctions = new TokenWithSanctions(address(this), "TokenWithSanctions", "TWS");
        return tokenWithSanctions;
    }
}