// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {StakingRewards} from "../../../src/week7-8/ecosystem1/StakingRewards.sol";
import {RewardsToken} from "../../../src/week7-8/ecosystem1/RewardsToken.sol";
import {StakingNFT} from "../../../src/week7-8/ecosystem1/StakingNFT.sol";


contract StakingRewardsTest is Test {

    uint256 public constant mintPrice = 0.07 ether;
    uint256 public constant discountPercentage = 15;
    bytes32 public constant merkleRoot = 0x6bb0d38d40cd012717a4c006cf73055b31f2e3ac5970b8a26f0a2c5411a4196c; // Example merkle root, replace with actual
    address public constant user = 0x47D1111fEC887a7BEb7839bBf0E1b3d215669D86; // Example
    
    address public owner = makeAddr("owner");
    address public alice = address(0x1);
    address public bob = address(0x2);

    StakingNFT public nft;
    StakingRewards public stakingRewards;
    RewardsToken public rewardsToken;

    function setUp() public {
        nft = new StakingNFT(owner, mintPrice, discountPercentage, merkleRoot, "TestNFT", "TNFT", owner);
        stakingRewards = new StakingRewards(address(nft));
        rewardsToken = RewardsToken(stakingRewards.getRewardsToken());

        // Prepare a valid merkle proof (mocked for this example)
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = 0x0;
        deal(owner, mintPrice);
        deal(alice, mintPrice);
        deal(bob, mintPrice);
        deal(user, mintPrice);
        // Mint nfts to Alice and Bob
        nft.safeMint{value: mintPrice}(owner, merkleProof);
        nft.safeMint{value: mintPrice}(alice, merkleProof);
        nft.safeMint{value: mintPrice}(bob, merkleProof);
        nft.safeMint{value: mintPrice}(user, merkleProof);
    }

    function testOnERC721Received() public {
        vm.startPrank(alice);
        nft.approve(address(stakingRewards), 1);
        
        // Encode the staking consent
        bytes memory data = abi.encode(true);
        
        nft.safeTransferFrom(alice, address(stakingRewards), 1, data);
        vm.stopPrank();

        assertEq(stakingRewards.getNoOfStakedNfts(alice), 1);
        assertEq(stakingRewards.nft_stakers(1), alice);
    }

    function testStakeFor() public {
        vm.startPrank(alice);
        nft.approve(address(stakingRewards), 1);
        stakingRewards.stakeFor(alice, 1);
        vm.stopPrank();

        assertEq(stakingRewards.getNoOfStakedNfts(alice), 1);
        assertEq(stakingRewards.nft_stakers(1), alice);
    }

    function testStakeForAnotherUserFail() public {
        vm.prank(bob);
        nft.approve(address(stakingRewards), 2);

        vm.prank(alice);
        vm.expectRevert();
        stakingRewards.stakeFor(bob, 2);
    }

    function testWithdrawRewards() public {
        // Stake an NFT
        vm.startPrank(alice);
        nft.approve(address(stakingRewards), 1);
        uint256 initialBalance = rewardsToken.balanceOf(alice);
        stakingRewards.stakeFor(alice, 1);

        // Fast forward time
        vm.warp(block.timestamp + stakingRewards.REWARDS_INTERVAL() + 1);

        stakingRewards.withdrawRewards();
        vm.stopPrank();

        uint256 finalBalance = rewardsToken.balanceOf(alice);

        assert(finalBalance > initialBalance);
    }

    function testWithdraw() public {
        // Stake an NFT
        vm.startPrank(alice);
        nft.approve(address(stakingRewards), 1);
        stakingRewards.stakeFor(alice, 1);

        // Withdraw the NFT
        stakingRewards.withdraw(1);
        vm.stopPrank();

        assertEq(stakingRewards.getNoOfStakedNfts(alice), 0);
        assertEq(stakingRewards.nft_stakers(1), address(0));
        assertEq(nft.ownerOf(1), alice);
    }

    function testExit() public {
        // Mint another NFT to Alice
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = 0x0;
        deal(alice, mintPrice);
        // Mint nfts to Alice and Bob
        nft.safeMint{value: mintPrice}(alice, merkleProof);
        // Stake two NFTs
        vm.startPrank(alice);
        nft.approve(address(stakingRewards), 1);
        nft.approve(address(stakingRewards), 4);
        stakingRewards.stakeFor(alice, 1);
        stakingRewards.stakeFor(alice, 4);

        // Fast forward time
        vm.warp(block.timestamp + stakingRewards.REWARDS_INTERVAL() + 1);

        uint256 initialBalance = rewardsToken.balanceOf(alice);
        stakingRewards.exit();
        uint256 finalBalance = rewardsToken.balanceOf(alice);

        assert(finalBalance > initialBalance);
        assertEq(stakingRewards.getNoOfStakedNfts(alice), 0);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(4), alice);
        vm.stopPrank();
    }

    function testRewardsIncreaseWithAdditionalStakedNFTs() public {
        // Mint another NFT to Alice
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = 0x0;
        deal(alice, mintPrice);
        // Mint nfts to Alice and Bob
        nft.safeMint{value: mintPrice}(alice, merkleProof);
        vm.startPrank(alice);
        nft.approve(address(stakingRewards), 1);
        nft.approve(address(stakingRewards), 4);
        
        // Stake first NFT
        stakingRewards.stakeFor(alice, 1);
        
        // Fast forward time
        vm.warp(block.timestamp + stakingRewards.REWARDS_INTERVAL() + 1);
        
        uint256 rewardsWithOneNFT = stakingRewards.getRewardsAmount(alice);
        
        // Stake second NFT
        stakingRewards.stakeFor(alice, 4);
        
        // Fast forward time again
        vm.warp(block.timestamp + stakingRewards.REWARDS_INTERVAL() + 1);
        
        uint256 rewardsWithTwoNFTs = stakingRewards.getRewardsAmount(alice) - rewardsWithOneNFT;
        
        // Check if rewards with two NFTs are higher
        assert(rewardsWithTwoNFTs > rewardsWithOneNFT);
        vm.stopPrank();
    }
}