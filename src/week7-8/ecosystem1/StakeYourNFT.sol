// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {RewardToken} from "./RewardToken.sol";

contract StakeYourNFT is IERC721Receiver {

    error StakeYourNFT__NotOwner();

    IERC721 private nft;
    RewardToken private rewardToken;

    constructor(address nftAddress) {
        nft = IERC721(nftAddress);
        rewardToken = new RewardToken("Reward Token", "RWD");
    }

    

    // smart contract that can mint new ERC20 tokens and receive ERC721 tokens. 
    // A classic feature of NFTs is being able to receive them to stake tokens. 
    // Users can send their NFTs and withdraw 10 ERC20 tokens every 24 hours. Don’t forget about decimal places! 
    // The user can withdraw the NFT at any time. The smart contract must take possession of the NFT and only the user should be able to withdraw it. 
    // IMPORTANT: your staking mechanism must follow the sequence suggested in https://www.rareskills.io/post/erc721 under “Gas efficient staking, bypassing approval”

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
        return this.onERC721Received.selector;
    }
}
