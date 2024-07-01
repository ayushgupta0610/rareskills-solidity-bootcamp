// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithGodMode} from "../src/week1/TokenWithGodMode.sol";

contract TokenWithSanctionsTest is Test {
    TokenWithGodMode public tokenWithGodMode;

    address public ADMIN = makeAddr("admin");
    string public constant NAME = "TokenWithSanctions";
    string public constant SYMBOL = "TWS";

    function setUp() public {
        tokenWithGodMode = new TokenWithGodMode(ADMIN, NAME, SYMBOL);
    }

    // test if the admin/god can transfer tokens between addresses
    // test if no other person can transfer tokens between addresses
    // test erc20 functionalities?
}
