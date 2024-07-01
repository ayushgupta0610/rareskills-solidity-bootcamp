// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithSanctions} from "../src/week1/TokenWithSanctions.sol";

contract CounterTest is Test {
    TokenWithSanctions public tokenWithSanctions;

    address public ADMIN = makeAddr("admin");
    string public constant NAME = "TokenWithSanctions";
    string public constant SYMBOL = "TWS";

    function setUp() public {
        tokenWithSanctions = new TokenWithSanctions(ADMIN, NAME, SYMBOL);
    }

}
