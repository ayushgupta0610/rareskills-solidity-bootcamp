// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../../src/week7-8/ecosystem1/StakingNFT.sol";

contract StakingNFTTest is Test {
    StakingNFT public stakingNFT;
    address public owner;
    address public user;
    uint256 public mintPrice = 1 ether;
    bytes32 public merkleRoot = 0x1070c12d75bd378e5ae6900a4ff91c5c42d789607e9b1674328219c0d4c21cec; // Example merkle root, replace with actual

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        stakingNFT = new StakingNFT(owner, mintPrice, merkleRoot, "TestNFT", "TNFT", owner);
    }

    function testSafeMintSuccess() public {
        // Prepare a valid merkle proof (mocked for this example)
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = 0x0; // Mocked proof

        // User mints with discount
        vm.prank(user);
        vm.deal(user, mintPrice); // Ensure user has enough ether
        stakingNFT.safeMint{value: mintPrice * 85 / 100}(user, merkleProof);

        assertEq(stakingNFT.balanceOf(user), 1, "User should have 1 NFT after minting");
    }

    function testSafeMintFailPriceNotMet() public {
        // Prepare a valid merkle proof (mocked for this example)
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = 0x0; // Mocked proof

        // User tries to mint without enough ether
        vm.prank(user);
        vm.deal(user, mintPrice / 2); // Insufficient funds

        vm.expectRevert("StakingNFT__MintPriceNotMet");
        stakingNFT.safeMint{value: mintPrice / 2}(user, merkleProof);
    }

    function testSafeMintFailMaxSupply() public {
        // Mint up to max supply
        for (uint i = 0; i < 1000; i++) {
            vm.prank(address(uint160(i)));
            stakingNFT.safeMint{value: mintPrice}(address(uint160(i)), new bytes32[](0));
        }

        // Next mint should fail
        vm.expectRevert("StakingNFT__MaxSupplyReached");
        stakingNFT.safeMint{value: mintPrice}(user, new bytes32[](0));
    }
}

// Whitelisted addresses
// const addresses: string[] = [
//     "0x47D1111fEC887a7BEb7839bBf0E1b3d215669D86",
//     "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", 
//     "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", 
//     "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", 
//     "0x90F79bf6EB2c4f870365E785982E1f101E93b906", 
//     "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65", 
//     "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc", 
//     "0x976EA74026E726554dB657fA54763abd0C3a0aa9", 
//     "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955", 
//     "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f", 
//     "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720"
// ];