// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {RewardsToken} from "./RewardsToken.sol";
import {IStakingRewards} from "./IStakingRewards.sol";

contract StakingRewards is IERC721Receiver, IStakingRewards, ReentrancyGuard {
    error StakingRewards__NotOwner();
    error StakingRewards__NoNFTStaked();
    error StakingRewards__Unauthorised();

    struct Rewards {
        uint256[] nftTokens;
        uint256 rewardsAccumulated;
        uint256 totalClaimedRewards;
        uint256 lastRewardsUpdated;
        uint256 rewardsRate; // for now assume that the rewards rate is constant, ie 10 tokens every 24 hours
    }

    uint256 private constant BASE_REWARDS_AMOUNT = 10 * 10 ** 18;
    uint256 public constant REWARDS_INTERVAL = 24 hours;
    uint256 private constant RATE_INCREASE_FACTOR = 5; // 5% increase per additional NFT staked

    IERC721 private nft;
    RewardsToken private rewardsToken;
    mapping(address => Rewards) public user_rewards;
    mapping(uint256 => address) public nft_stakers;

    constructor(address nftAddress) {
        nft = IERC721(nftAddress);
        rewardsToken = new RewardsToken("Rewards Token", "RWD"); // Can come in the form of parameters
    }

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
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (msg.sender != address(nft)) {
            revert StakingRewards__NotOwner();
        }

        // Decode the data to understand the user's intention
        bool toBeStaked = abi.decode(data, (bool));

        if (toBeStaked) {
            // Stake the NFT
           stakeFor(from, tokenId);
        }
        return this.onERC721Received.selector;
    }

    // Exit the staking pool
    function exit() external nonReentrant {
        // withdraw the nft token
        // withdraw the rewards
        Rewards storage rewards = user_rewards[msg.sender];
        // TODO: Optimise the below if possible (use batch transfer)
        for (uint256 i = 0; i < rewards.nftTokens.length; i++) {
            nft_stakers[rewards.nftTokens[i]] = address(0);
            nft.safeTransferFrom(
                address(this),
                msg.sender,
                rewards.nftTokens[i]
            );
        }
        rewards.nftTokens = new uint256[](0);

        if (block.timestamp > rewards.lastRewardsUpdated + REWARDS_INTERVAL) {
            uint256 timeFactor = (block.timestamp -
                rewards.lastRewardsUpdated) / REWARDS_INTERVAL;
            rewards.rewardsAccumulated += timeFactor * rewards.rewardsRate;
            rewards.lastRewardsUpdated += timeFactor * REWARDS_INTERVAL;
        }
        // transfer the rewards accumulated to the user
        rewardsToken.mint(msg.sender, rewards.rewardsAccumulated);
        rewards.totalClaimedRewards += rewards.rewardsAccumulated;
        rewards.rewardsAccumulated = 0;
    }

    function _updateRewards(Rewards storage rewards) internal {
        if (block.timestamp > rewards.lastRewardsUpdated + REWARDS_INTERVAL) {
            uint256 timeFactor = (block.timestamp - rewards.lastRewardsUpdated) / REWARDS_INTERVAL;
            rewards.rewardsAccumulated += timeFactor * rewards.rewardsRate;
            rewards.lastRewardsUpdated += timeFactor * REWARDS_INTERVAL;
        }
    }

    // Get the rewards accumulated for all the staked nfts by the user
    function withdrawRewards() public nonReentrant {
        Rewards storage rewards = user_rewards[msg.sender];
        if (rewards.nftTokens.length == 0) {
            revert StakingRewards__NoNFTStaked();
        }
        _updateRewards(rewards);
        rewardsToken.mint(msg.sender, rewards.rewardsAccumulated);
        rewards.totalClaimedRewards += rewards.rewardsAccumulated;
        rewards.rewardsAccumulated = 0;
    }

    // Stake the nft token
    function stakeFor(address user, uint256 tokenId) public {
        if (msg.sender == address(nft)) {
            nft_stakers[tokenId] = user;
        } else {
            nft_stakers[tokenId] = msg.sender;
        }
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        Rewards storage rewards = user_rewards[msg.sender];
        
        // Update rewards before changing the rate
        _updateRewards(rewards);
        
        rewards.nftTokens.push(tokenId);
        rewards.lastRewardsUpdated = block.timestamp;
        
        // Update rewards rate based on the number of staked NFTs
        rewards.rewardsRate = BASE_REWARDS_AMOUNT * (100 + (rewards.nftTokens.length - 1) * RATE_INCREASE_FACTOR) / 100;
    }

    // Withdraw the nft token
    function withdraw(uint256 tokenId) external nonReentrant {
        if (nft_stakers[tokenId] != msg.sender) {
            revert StakingRewards__Unauthorised();
        }
        Rewards storage rewards = user_rewards[msg.sender];
        
        // Update rewards before changing the rate
        _updateRewards(rewards);
        
        nft_stakers[tokenId] = address(0);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        
        uint256 index = 0;
        uint256 length = rewards.nftTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (rewards.nftTokens[i] == tokenId) {
                index = i;
                break;
            }
        }
        rewards.nftTokens[index] = rewards.nftTokens[rewards.nftTokens.length - 1];
        rewards.nftTokens.pop();
        
        // Update rewards rate based on the new number of staked NFTs
        rewards.rewardsRate = rewards.nftTokens.length > 0 
            ? BASE_REWARDS_AMOUNT * (100 + (rewards.nftTokens.length - 1) * RATE_INCREASE_FACTOR) / 100
            : 0;
    }

    function getNFTAllowed() external view returns (address) {
        return address(nft);
    }

    function getNoOfStakedNfts(address account) external view returns (uint256) {
        return user_rewards[account].nftTokens.length;
    }

    function getRewardsAmount(address account) external view returns (uint256) {
        Rewards storage rewards = user_rewards[account];
        if (rewards.nftTokens.length == 0) {
            return 0;
        }
        if (block.timestamp > rewards.lastRewardsUpdated + REWARDS_INTERVAL) {
            uint256 timeFactor = (block.timestamp -
                rewards.lastRewardsUpdated) / REWARDS_INTERVAL;
            return rewards.rewardsAccumulated + timeFactor * rewards.rewardsRate;
        } else {
            return rewards.rewardsAccumulated;
        }
    }

    function getRewardPerToken() external pure returns (uint256) {
        return BASE_REWARDS_AMOUNT;
    }

    function getRewardsToken() external view returns (address) {
        return address(rewardsToken);
    }

    function totalSupply() external view returns (uint256) {
        return rewardsToken.totalSupply();
    }

}
