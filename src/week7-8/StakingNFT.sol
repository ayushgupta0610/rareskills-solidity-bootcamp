// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; // Can be replaced with Ownable2Step.sol

contract StakingNFT is Ownable, ERC721, ERC721Enumerable, ERC2981 {

    uint256 public constant MAX_SUPPLY = 1000;

    modifier fixedTotalSupply() {
        require(totalSupply() <= MAX_SUPPLY, "Max supply reached");
        _;
    }

    constructor (address initalOwner, string memory name, string memory symbol) Ownable(initalOwner) ERC721(name, symbol) {
        // _setBaseURI(baseURI);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner fixedTotalSupply {
        _safeMint(to, tokenId);
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
}
