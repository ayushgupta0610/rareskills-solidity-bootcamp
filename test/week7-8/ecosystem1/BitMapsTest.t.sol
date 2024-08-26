// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract BitMapsTest is Test {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private bitmap;

    function setUp() public {
        // Setup is not needed for this test as the bitmap is already declared
    }

    function testSetAndGet() public {
        uint256 index = 42;

        // Initially, the bit should be unset
        assertFalse(bitmap.get(index));

        // Set the bit
        bitmap.set(index);

        // Check if the bit is set
        assertTrue(bitmap.get(index));
    }

    function testUnset() public {
        uint256 index = 100;

        // Set the bit
        bitmap.set(index);
        assertTrue(bitmap.get(index));

        // Unset the bit
        bitmap.unset(index);

        // Check if the bit is unset
        assertFalse(bitmap.get(index));
    }

    function testSetTo() public {
        uint256 index = 200;

        // Set to true
        bitmap.setTo(index, true);
        assertTrue(bitmap.get(index));

        // Set to false
        bitmap.setTo(index, false);
        assertFalse(bitmap.get(index));
    }

    function testMultipleBits() public {
        // Set multiple bits
        bitmap.set(0);
        bitmap.set(255);
        bitmap.set(256);

        // Check if the bits are set
        assertTrue(bitmap.get(0));
        assertTrue(bitmap.get(255));
        assertTrue(bitmap.get(256));

        // Check if other bits are unset
        assertFalse(bitmap.get(1));
        assertFalse(bitmap.get(254));
        assertFalse(bitmap.get(257));
    }

    function testFuzzSetAndGet(uint256 index) public {
        // Fuzz test for setting and getting bits
        bitmap.set(index);
        assertTrue(bitmap.get(index));
    }
}