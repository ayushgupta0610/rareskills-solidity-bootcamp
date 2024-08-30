// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract StakingNFT is Ownable2Step, ERC721, ERC721Enumerable, ERC2981 {
    using BitMaps for BitMaps.BitMap;

    error StakingNFT__MaxSupplyReached();
    error StakingNFT__TransferFailed();
    error StakingNFT__AlreadyClaimed();
    error StakingNFT__MintPriceNotMet();

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public immutable discountPercentage;
    uint256 public immutable priceToMint;
    bytes32 public immutable merkleRoot;
    uint256 private _nextTokenId;
    BitMaps.BitMap private _claimStatus;

    event ClaimStatusChanged(address indexed user, bool status);

    modifier fixedTotalSupply() {
        if (totalSupply() > MAX_SUPPLY-1) {
            revert StakingNFT__MaxSupplyReached();
        }
        _;
    }

    constructor (address initialOwner, uint256 mintPrice, uint256 discountPercent, bytes32 merkleRootBytes32, string memory name, string memory symbol, address royaltyReceiver) Ownable(initialOwner) ERC721(name, symbol) {
        _setDefaultRoyalty(royaltyReceiver, 250);
        priceToMint = mintPrice;
        discountPercentage = discountPercent;
        merkleRoot = merkleRootBytes32;
    }

    // Add discount functionality for merkle tree verified addresses
    // Enter merkleProof as empty bytes array for the case of regular (and not discounted) minting
    function safeMint(address to, bytes32[] calldata merkleProof) public payable fixedTotalSupply {
        uint256 tokenId = _nextTokenId++;
        // Verify the merkle proof.
        uint256 quantity = 1;
        bytes32 node = keccak256(abi.encodePacked(to, quantity));
        if (MerkleProof.verify(merkleProof, merkleRoot, node)){
            if (msg.value < ((priceToMint*(100-discountPercentage))/100)) {
                revert StakingNFT__MintPriceNotMet();
            }
            if (hasUserClaimed(to)) {
                revert StakingNFT__AlreadyClaimed();
            }
            emit ClaimStatusChanged(to, true);
            // Make the claim status true for all the users initially to save gas when setting the bit to false later
            // Get the status if the user has not claimed already (true), then allow the user to claim and set the status to false
            _claimStatus.set(uint256(uint160(to)));
        } else if (msg.value < priceToMint) {
            revert StakingNFT__MintPriceNotMet();
        }
        _safeMint(to, tokenId);
    }

    function hasUserClaimed(address user) public view returns (bool) {
        return _claimStatus.get(uint256(uint160(user)));
    } 

    // The following functions are overrides required by Solidity.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return interfaceId == type(ERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert StakingNFT__TransferFailed();
        }
    }
}
