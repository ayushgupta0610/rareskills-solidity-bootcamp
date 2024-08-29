// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";
import {NFTEnumerable} from "./NFTEnumerable.sol";

contract PrimeCounter {

    // Get the count of the prime numbers tokenIds a user has
    function getPrimeCount(NFTEnumerable nft, address user) public view returns(uint256) {
        uint256[] memory tokenIds = getTokenIdsOf(nft, user);
        uint256 primeCount = 0;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            if(isPrime(tokenIds[i])) primeCount++;
        }
        return primeCount;
    }

    function getTokenIdsOf(NFTEnumerable nft, address user) public view returns(uint256[] memory) {
        // Get total number of nfts owned by user
        uint256 balance = nft.balanceOf(user);
        // Array to store tokenIds
        uint256[] memory tokenIds = new uint256[](balance);
        // Iterate through balance and get each tokenId
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(user, i);
            tokenIds[i] = tokenId;
        }
        return tokenIds;
    }
    
    function isPrime(uint256 num) public pure returns(bool) {
        uint256 sqrtNumber = FixedPointMathLib.sqrt(num);
        for(uint256 i = 2; i <= sqrtNumber; i++) {
            if(num % i == 0) return false;
        }
        return num > 1;
    }

}