// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
interface IStakingRewards {
    // Views

    function getNFTAllowed() external view returns (address);

    function getNoOfStakedNfts(address account) external view returns (uint256);

    function getRewardsAmount(address account) external view returns (uint256);

    function getRewardPerToken() external view returns (uint256);

    function getRewardsToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    // Mutative

    // Exit the staking pool
    function exit() external;

    // Get the rewards accumulated for all the staked nfts by the user
    function withdrawRewards() external;

    // Stake the nft token
    function stakeFor(address user, uint256 tokenId) external;

    // Withdraw the nft token
    function withdraw(uint256 tokenId) external;
}