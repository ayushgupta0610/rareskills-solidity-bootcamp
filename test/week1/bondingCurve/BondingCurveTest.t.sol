// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurve} from "../../../src/week1/bondingCurve/BondingCurve.sol";
import {Token} from "../../../src/week1/bondingCurve/Token.sol";

contract BondingCurveTest is Test {

    BondingCurve public bondingCurve;
    Token public token;

    address public ADMIN = makeAddr("admin");
    address public USER_1 = makeAddr("user1");
    address public USER_2 = makeAddr("user2");
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 constant TOKEN_DECIMAL = 18;

    function setUp() public {
        vm.startPrank(ADMIN);
        token = new Token(ADMIN);
        bondingCurve = new BondingCurve(ADMIN, address(token));
        token.transferOwnership(address(bondingCurve));
        vm.stopPrank();
        vm.deal(USER_1, STARTING_BALANCE);
        vm.deal(USER_2, STARTING_BALANCE);
    }

    function testBuyTokens() external payable {
        vm.startPrank(USER_1);
        uint256 fiatValue = 4 ether;
        uint256 noOfTokens = 2 ether; // 2 tokens since the decimal value is 18
        uint256 requiredValueToMintTokens = bondingCurve.getNoOfTokensThatCanBeMintedWith(fiatValue);
        uint256 deadline = block.timestamp;
        bondingCurve.buyTokens{value: fiatValue}(noOfTokens, requiredValueToMintTokens, deadline);
        vm.stopPrank();
        assertEq(token.balanceOf(USER_1), noOfTokens);
    }

    function testSellTokens() external {
        vm.startPrank(USER_1);
        uint256 fiatValue = 4 ether;
        uint256 noOfTokens = 2 ether; // 2 tokens since the decimal value is 18
        uint256 requiredValueToMintTokens = bondingCurve.getNoOfTokensThatCanBeMintedWith(fiatValue);
        uint256 deadline = block.timestamp;
        bondingCurve.buyTokens{value: fiatValue}(noOfTokens, requiredValueToMintTokens, deadline);
        uint256 tokensToSell = 1 ether;
        uint256 requiredValueToSellTokens = bondingCurve.getValueToReceiveFromTokens(tokensToSell);
        bondingCurve.sellTokens(tokensToSell, requiredValueToSellTokens, deadline);
        vm.stopPrank();
        assertEq(token.balanceOf(USER_1), noOfTokens - tokensToSell);
        assertEq(address(USER_1).balance, STARTING_BALANCE - (noOfTokens - tokensToSell) ** 2 / 10 ** TOKEN_DECIMAL);
    }

    function testGetBuyPriceForTokens() external view {
        assertEq(bondingCurve.getBuyPriceForTokens(3 ether), 9 ether);
    }
}
