// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {RewardsToken} from "./RewardsToken.sol";
import {IStakingRewards} from "./IStakingRewards.sol";

contract StakingRewards is IERC721Receiver, IStakingRewards {

    error StakeYourNFT__NotOwner();

    struct Rewards {
        uint256[] nftTokens;
        uint256 lastDepositedTime;
        uint256 rewardsAccumulated;
        uint256 totalClaimedRewards;
        uint256 lastRewardsUpdated;
        uint256 rewardsRate; // in case the user has deposited various nft tokens at different time intervals
    }

    uint256 private constant REWARDS_AMOUNT = 10 * 10**18;
    uint256 public constant REWARDS_INTERVAL = 24 hours;
    IERC721 private nft;
    RewardsToken private rewardsToken;
    mapping(address => Rewards) public user_rewards;
    mapping(uint256 => address) public nft_stakers;
    
    constructor(address nftAddress) {
        nft = IERC721(nftAddress);
        rewardsToken = new RewardsToken("Rewards Token", "RWD"); // Can come in the form of parameters
    }

    // smart contract that can mint new ERC20 tokens and receive ERC721 tokens.  - Done
    // A classic feature of NFTs is being able to receive them to stake tokens.  - 
    // Users can send their NFTs and withdraw 10 ERC20 tokens every 24 hours. Don’t forget about decimal places! 
    // The user can withdraw the NFT at any time. The smart contract must take possession of the NFT and only the user should be able to withdraw it. 

    receive() external payable {}

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (msg.sender != address(nft)) {
            revert StakeYourNFT__NotOwner();
        }
        // decode data in case the user wants to stake their nft
        // if the user wants to stake their nft, mint 10 reward tokens to the user every 24 hours
        // if the user wants to withdraw their nft, transfer the nft back to the user
        // if the user wants to withdraw their reward tokens, transfer 10 reward tokens to the user
        // if the user wants to withdraw their nft and reward tokens, transfer the nft back to the user and 10 reward tokens to the user

        return this.onERC721Received.selector;
    }

    // Exit the staking pool
    function exit() external {
        // withdraw the nft token
        // withdraw the rewards
        
    }

    // Get the rewards accumulated for all the staked nfts by the user
    function withdrawRewards() external;

    // Stake the nft token
    function stake(uint256 tokenId) external;

    // Withdraw the nft token
    function withdraw(uint256 tokenId) external;


    function getNFTAllowed() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function getRewardsAmount(address account) external view returns (uint256);

    function getRewardPerToken() external view returns (uint256);

    function getRewardsToken() external view returns (address);

    function totalSupply() external view returns (uint256);

}
