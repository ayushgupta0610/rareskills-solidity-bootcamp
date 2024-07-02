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

    function setUp() public {
        vm.startPrank(ADMIN);
        token = new Token(ADMIN);
        bondingCurve = new BondingCurve(ADMIN, address(token));
        token.transferOwnership(address(bondingCurve));
        vm.stopPrank();
    }

    // test getBuyPriceForTokens function
    function testGetBuyPriceForTokens() public view {
        uint256 noOfTokens = 10;
        uint256 expectedPrice = 1000_000_000 * 10;
        uint256 actualPrice = bondingCurve.getBuyPriceForTokens(noOfTokens);
        assertEq(actualPrice, expectedPrice);
    }

    // test getTokenPriceInWei
}
