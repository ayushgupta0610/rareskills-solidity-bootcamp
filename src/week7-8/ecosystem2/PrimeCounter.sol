// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PrimeCounter {
    function countPrimes(uint256[] calldata numbers) public pure returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < numbers.length; i++) {
            if (isPrime(numbers[i])) {
                count++;
            }
        }
        return count;
    }

    function isPrime(uint256 n) internal pure returns (bool) {
        if (n <= 1) return false;
        if (n == 2 || n == 3) return true;
        if (n % 2 == 0 || n % 3 == 0) return false;

        uint256[] memory witnesses = new uint256[](3);
        witnesses[0] = 2;
        witnesses[1] = 7;
        witnesses[2] = 61;

        for (uint256 i = 0; i < witnesses.length; i++) {
            if (witnesses[i] >= n) break;
            if (!millerRabinTest(n, witnesses[i])) {
                return false;
            }
        }
        return true;
    }

    function millerRabinTest(uint256 n, uint256 a) internal pure returns (bool) {
        uint256 d = n - 1;
        uint256 s = 0;
        while (d % 2 == 0) {
            d /= 2;
            s++;
        }

        uint256 x = modExp(a, d, n);
        if (x == 1 || x == n - 1) return true;

        for (uint256 r = 1; r < s; r++) {
            x = mulMod(x, x, n);
            if (x == n - 1) return true;
        }
        return false;
    }

    function modExp(uint256 base, uint256 exponent, uint256 modulus) internal pure returns (uint256) {
        uint256 result = 1;
        base = base % modulus;
        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = mulMod(result, base, modulus);
            }
            exponent = exponent / 2;
            base = mulMod(base, base, modulus);
        }
        return result;
    }

    function mulMod(uint256 a, uint256 b, uint256 modulus) internal pure returns (uint256) {
        uint256 res = 0;
        a = a % modulus;
        while (b > 0) {
            if (b % 2 == 1) {
                res = (res + a) % modulus;
            }
            a = (a * 2) % modulus;
            b = b / 2;
        }
        return res % modulus;
    }
}