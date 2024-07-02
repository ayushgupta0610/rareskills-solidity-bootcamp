// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithGodMode} from "../src/week1/TokenWithGodMode.sol";

contract TokenWithSanctionsTest is Test {
    TokenWithGodMode public tokenWithGodMode;

    address public GOD = makeAddr("god");
    string public constant NAME = "TokenWithGodMode";
    string public constant SYMBOL = "TWG";

    function setUp() public {
        tokenWithGodMode = new TokenWithGodMode(GOD, NAME, SYMBOL);
    }

    // test if the god can transfer tokens between addresses
    // test if no other person can transfer tokens between addresses
    // test erc20 functionalities?
}
