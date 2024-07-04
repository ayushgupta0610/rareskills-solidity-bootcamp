// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurve} from "../../src/week1/bondingCurve/BondingCurve.sol";
import {Token} from "../../src/week1/bondingCurve/Token.sol";

contract BondingCurveTest is Test {

    BondingCurve public bondingCurve;
    Token public token;

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

    // function testBuyTokens() external payable {
    //     vm.startPrank(USER_1);
    //     bondingCurve.buyTokens{value: 4 ether}(2 ether);
    //     vm.stopPrank();
    //     assertEq(token.balanceOf(USER_1), 2 ether);
    // }

    // function testGetValueToReceiveFromTokens() external {
    //     vm.startPrank(USER_1);
    //     bondingCurve.buyTokens{value: 4 ether}(2 ether);
    //     vm.stopPrank();
    //     assertEq(bondingCurve.getValueToReceiveFromTokens(1 ether), 3 ether);
    // }

    // function testSellTokens() external {
    //     vm.startPrank(USER_1);
    //     bondingCurve.buyTokens{value: 4 ether}(2 ether);
    //     bondingCurve.sellTokens(1 ether);
    //     vm.stopPrank();
    //     assertEq(token.balanceOf(USER_1), 1 ether);
    //     assertEq(address(USER_1).balance, 99 ether);
    // }

    function testGetBuyPriceForTokens() external view {
        assertEq(bondingCurve.getBuyPriceForTokens(3 ether), 9 ether);
    }
}
