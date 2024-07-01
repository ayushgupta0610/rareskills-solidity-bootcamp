// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithSanctions} from "../src/week1/TokenWithSanctions.sol";

contract TokenWithSanctionsTest is Test {
    TokenWithSanctions public tokenWithSanctions;

    address public ADMIN = makeAddr("admin");
    string public constant NAME = "TokenWithSanctions";
    string public constant SYMBOL = "TWS";

    function setUp() public {
        tokenWithSanctions = new TokenWithSanctions(ADMIN, NAME, SYMBOL);
    }

    // test if admin can set and remove the blacklist
    // test if no other person can set the blacklist
    // test if blacklisted account can't transfer tokens
    // test erc20 functionalities?

    // Generate foundry test cases for erc20 functionalities
    // function test_erc20() public {
    //     // test if the contract is deployed with the correct name and symbol
    //     assertEq(tokenWithSanctions.name(), NAME);
    //     assertEq(tokenWithSanctions.symbol(), SYMBOL);

    //     // test if the contract is deployed with the correct admin
    //     assertEq(tokenWithSanctions.getRoleMemberCount(tokenWithSanctions.ADMIN()), 1);
    //     assertEq(tokenWithSanctions.getRoleMember(tokenWithSanctions.ADMIN(), 0), ADMIN);

    //     // test if the contract is deployed with the correct admin
    //     assertEq(tokenWithSanctions.getRoleMemberCount(tokenWithSanctions.ADMIN()), 1);
    //     assertEq(tokenWithSanctions.getRoleMember(tokenWithSanctions.ADMIN(), 0), ADMIN);

    //     // test if the admin can set the blacklist
    //     address account = makeAddr("account");
    //     tokenWithSanctions.setBlacklist(account, true);
    //     assert(tokenWithSanctions.isBlacklistedAccount(account));

    //     // test if the admin can remove the blacklist
    //     tokenWithSanctions.setBlacklist(account, false);
    //     assert(!tokenWithSanctions.isBlacklistedAccount(account));

    //     // test if no other person can set the blacklist
    //     address other = makeAddr("other");
    //     tokenWithSanctions.setBlacklist(account, true, {from: other});
    //     assert(!tokenWithSanctions.isBlacklistedAccount(account));

    //     // test if blacklisted account can't transfer tokens
    //     tokenWithSanctions.setBlacklist(account, true);
    //     tokenWithSanctions.mint(account, 100);
    //     tokenWithSanctions.transfer(makeAddr("recipient"), 100, {from: account});
    //     assertEq(tokenWithSanctions.balanceOf(account), 100);
    // }

}
