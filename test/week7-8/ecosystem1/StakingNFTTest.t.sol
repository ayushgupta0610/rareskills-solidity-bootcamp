// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {StakingNFT} from "../../../src/week7-8/ecosystem1/StakingNFT.sol";

contract StakingNFTTest is Test {
    
    uint256 public constant mintPrice = 0.07 ether;
    uint256 public constant discountPercentage = 15;
    bytes32 public constant merkleRoot = 0x6bb0d38d40cd012717a4c006cf73055b31f2e3ac5970b8a26f0a2c5411a4196c; // Example merkle root, replace with actual
    address public constant user = 0x47D1111fEC887a7BEb7839bBf0E1b3d215669D86; // Example
    address public owner = makeAddr("owner");
    StakingNFT public stakingNFT;
    
    function setUp() public {
        stakingNFT = new StakingNFT(owner, mintPrice, discountPercentage, merkleRoot, "TestNFT", "TNFT", owner);
    }

    function testSafeMintSuccess() public {

        // Prepare a valid merkle proof (mocked for this example)
        bytes32[] memory merkleProof = new bytes32[](3);
        merkleProof[0] = 0x320723cfc0bfa9b0f7c5b275a01ffa5e0f111f05723ba5df2b2684ab86bebe06; // Mocked proof
        merkleProof[1] = 0x1838245b08d1e921c5c0b6c7aede4f17dd9b159feaee59ffebba9fd6c4bccb03; // Mocked proof
        merkleProof[2] = 0xf9517e24d5f1f504da5daaa3122e9e4ac7b4200955f2e27810823053adb24344; // Mocked proof

        // User mints with discount
        vm.deal(user, mintPrice); // Ensure user has enough ether
        vm.prank(user);
        uint256 discountMintPrice = (mintPrice * (100 - discountPercentage))/ 100;
        stakingNFT.safeMint{value: discountMintPrice}(user, merkleProof);

        assertEq(stakingNFT.balanceOf(user), 1, "User should have 1 NFT after minting");
    }

    function testSafeMintFailPriceNotMet() public {
        // Prepare a valid merkle proof (mocked for this example)
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = 0x0; // Mocked proof

        // User tries to mint without enough ether
        vm.prank(user);
        vm.deal(user, mintPrice); // Insufficient funds

        vm.expectRevert(StakingNFT.StakingNFT__MintPriceNotMet.selector);
        stakingNFT.safeMint{value: (mintPrice * (100 - discountPercentage))/ 100}(user, merkleProof);
    }

    function testSafeMintFailMaxSupply() public {
        // Mint up to max supply
        for (uint i = 1; i < 1001; i++) {
            vm.deal(address(uint160(i)), mintPrice);
            vm.prank(address(uint160(i)));
            stakingNFT.safeMint{value: mintPrice}(address(uint160(i)), new bytes32[](0));
        }

        // Next mint should fail
        vm.expectRevert(StakingNFT.StakingNFT__MaxSupplyReached.selector);
        stakingNFT.safeMint{value: mintPrice}(user, new bytes32[](0));
    }

    function testSafeMintFailAlreadyClaimed() public {
        // Prepare a valid merkle proof (mocked for this example)
        bytes32[] memory merkleProof = new bytes32[](3);
        merkleProof[0] = 0x320723cfc0bfa9b0f7c5b275a01ffa5e0f111f05723ba5df2b2684ab86bebe06; // Mocked proof
        merkleProof[1] = 0x1838245b08d1e921c5c0b6c7aede4f17dd9b159feaee59ffebba9fd6c4bccb03; // Mocked proof
        merkleProof[2] = 0xf9517e24d5f1f504da5daaa3122e9e4ac7b4200955f2e27810823053adb24344; // Mocked proof

        deal(user, mintPrice*2);

        // User mints
        vm.prank(user);
        stakingNFT.safeMint{value: mintPrice}(user, merkleProof);

        // Next mint should fail
        vm.expectRevert(StakingNFT.StakingNFT__AlreadyClaimed.selector);
        stakingNFT.safeMint{value: mintPrice}(user, merkleProof);
    }

    function testWithdrawFundsByOwner() public {
        vm.prank(owner);
        stakingNFT.withdraw();
    }

    function testWithdrawFailNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        stakingNFT.withdraw();
    }

}
// Whitelisted addresses
// const addresses: string[] = [
//     "0x47D1111fEC887a7BEb7839bBf0E1b3d215669D86", // 1
//     "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", // 1
//     "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", // 1
//     "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", // 1   
//     "0x90F79bf6EB2c4f870365E785982E1f101E93b906", // 1
//     "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65", // 1
// ];
