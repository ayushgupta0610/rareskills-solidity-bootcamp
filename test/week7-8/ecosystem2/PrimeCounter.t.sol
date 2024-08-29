// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/week7-8/ecosystem2/PrimeCounter.sol";
import "../../../src/week7-8/ecosystem2/NFTEnumerable.sol";

contract PrimeCounterTest is Test {
    PrimeCounter public primeCounter;
    NFTEnumerable public nft;
    address public user1;
    address public user2;

    function setUp() public {
        primeCounter = new PrimeCounter();
        nft = new NFTEnumerable();
        user1 = address(0x1);
        user2 = address(0x2);
    }

    function testIsPrime() public view {
        assertTrue(primeCounter.isPrime(2));
        assertTrue(primeCounter.isPrime(3));
        assertTrue(primeCounter.isPrime(5));
        assertTrue(primeCounter.isPrime(7));
        assertTrue(primeCounter.isPrime(11));
        assertTrue(primeCounter.isPrime(97));

        assertFalse(primeCounter.isPrime(1));
        assertFalse(primeCounter.isPrime(4));
        assertFalse(primeCounter.isPrime(6));
        assertFalse(primeCounter.isPrime(100));
    }

    function testGetTokenIdsOf() public {
        // Mint some NFTs to user1
        nft.mint(user1, 1);
        nft.mint(user1, 2);
        nft.mint(user1, 3);

        uint256[] memory tokenIds = primeCounter.getTokenIdsOf(nft, user1);
        
        assertEq(tokenIds.length, 3);
        assertEq(tokenIds[0], 1);
        assertEq(tokenIds[1], 2);
        assertEq(tokenIds[2], 3);
    }

    function testGetPrimeCount() public {
        // Mint some NFTs to user1 and user2
        nft.mint(user1, 2);  // prime
        nft.mint(user1, 3);  // prime
        nft.mint(user1, 4);  // not prime
        nft.mint(user1, 5);  // prime
        
        nft.mint(user2, 1);  // not prime
        nft.mint(user2, 6);  // not prime
        nft.mint(user2, 7);  // prime

        uint256 primeCountUser1 = primeCounter.getPrimeCount(nft, user1);
        uint256 primeCountUser2 = primeCounter.getPrimeCount(nft, user2);

        assertEq(primeCountUser1, 3);
        assertEq(primeCountUser2, 1);
    }

    function testGetPrimeCountWithNoNFTs() public view {
        uint256 primeCount = primeCounter.getPrimeCount(nft, address(0x3));
        assertEq(primeCount, 0);
    }

    function testGetTokenIdsOfWithNoNFTs() public view {
        uint256[] memory tokenIds = primeCounter.getTokenIdsOf(nft, address(0x3));
        assertEq(tokenIds.length, 0);
    }
}