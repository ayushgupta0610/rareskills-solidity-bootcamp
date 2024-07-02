// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithGodMode} from "../src/week1/TokenWithGodMode.sol";

contract TokenWithGodModeTest is Test {
    TokenWithGodMode public tokenWithGodMode;

    address public GOD = makeAddr("god");
    address public USER = makeAddr("user");
    address public ACCOUNT = makeAddr("account");
    string public constant NAME = "TokenWithGodMode";
    string public constant SYMBOL = "TWG";

    function setUp() public {
        tokenWithGodMode = new TokenWithGodMode(GOD, NAME, SYMBOL);
        vm.startPrank(GOD);
        tokenWithGodMode.transfer(USER, 100 ether);
        tokenWithGodMode.transfer(ACCOUNT, 100 ether);
        vm.stopPrank();
    }

    // Test if god can transfer tokens between addresses
    function testGodCanTransfer() public {
        uint256 initialBalanceOfUser = tokenWithGodMode.balanceOf(USER);
        uint256 initialBalanceOfAccount = tokenWithGodMode.balanceOf(ACCOUNT);
        vm.startPrank(GOD);
        tokenWithGodMode.transfer(USER, ACCOUNT, 10 ether);
        assertEq(tokenWithGodMode.balanceOf(USER), initialBalanceOfUser - 10 ether);
        assertEq(tokenWithGodMode.balanceOf(ACCOUNT), initialBalanceOfAccount + 10 ether);
        vm.stopPrank();
    }

    // Test if no other person can transfer tokens between addresses
    function testRevertsIfUserTransfersFromAnotherAccount() public {
        vm.startPrank(USER);
        vm.expectRevert(TokenWithGodMode.TokenWithGodMode__RestrictedToGod.selector);
        tokenWithGodMode.transfer(ACCOUNT, USER, 10 ether);
        vm.stopPrank();
    }

    // test erc20 functionalities?
}
