// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {StakingRewards, RewardsToken} from "../../../src/week7-8/ecosystem1/StakingRewards.sol";
import {StakingNFT} from "../../../src/week7-8/ecosystem1/StakingNFT.sol";
// import "../../../src/week7-8/ecosystem1/RewardsToken.sol";

contract StakingRewardsTest is Test {
    StakingRewards stakingRewards;
    StakingNFT stakingNFT;
    RewardsToken rewardsToken;
    address user = address(1);

    function setUp() public {
        stakingNFT = new StakingNFT(address(this), 0.1 ether, 15, 0x0, "StakeNFT", "SNFT", address(this));
        rewardsToken = new RewardsToken("Rewards Token", "RWD");
        stakingRewards = new StakingRewards(address(stakingNFT));
        vm.startPrank(user);
        stakingNFT.safeMint(user, new bytes32[](0));
        vm.stopPrank();
    }

    function testStakeNFT() public {
        uint256 tokenId = 0;
        vm.startPrank(user);
        stakingNFT.approve(address(stakingRewards), tokenId);
        stakingRewards.stakeFor(user, tokenId);
        assertEq(stakingRewards.getNoOfStakedNfts(user), 1);
        vm.stopPrank();
    }

    function testRewardAccumulation() public {
        testStakeNFT();
        vm.warp(block.timestamp + 1 days);
        uint256 expectedRewards = 10 * 10 ** 18; // Assuming 10 tokens per day
        assertEq(stakingRewards.getRewardsAmount(user), expectedRewards);
    }

    function testWithdrawRewards() public {
        testRewardAccumulation();
        vm.startPrank(user);
        stakingRewards.withdrawRewards();
        assertEq(rewardsToken.balanceOf(user), 10 * 10 ** 18);
        vm.stopPrank();
    }
}