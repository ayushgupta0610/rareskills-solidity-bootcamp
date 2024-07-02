// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurve} from "../../src/week1/bondingCurve/BondingCurve.sol";
import {Token} from "../../src/week1/bondingCurve/Token.sol";

contract BondingCurveTest is Test {

    BondingCurve public bondingCurve;
    Token public token;

    string public constant NAME = "BondingCurve";
    string public constant SYMBOL = "BC";
    address public ADMIN = makeAddr("admin");
    address public USER_1 = makeAddr("user1");
    address public USER_2 = makeAddr("user2");

    function setUp() public {
        vm.startPrank(ADMIN);
        token = new Token(ADMIN);
        bondingCurve = new BondingCurve(ADMIN, address(token));
        token.transferOwnership(address(bondingCurve));
        vm.stopPrank();
        vm.deal(USER_1, 100 ether);
        vm.deal(USER_2, 100 ether);
    }

    // test getBuyPriceForTokens function
    function testBuyTokens() external payable {
        vm.startPrank(USER_1);
        bondingCurve.buyTokens{value: 2 ether}(2);
        vm.stopPrank();
        assertEq(token.balanceOf(USER_1), 2);
    }

    // test getTokenPriceInWei
}
