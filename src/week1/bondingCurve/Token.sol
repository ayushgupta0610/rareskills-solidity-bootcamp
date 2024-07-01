// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 *     @title Token contract with limitless supply
 *     @author Ayush Gupta
 *     @dev This contract is a token contract that can be minted and burned by
 *     @notice Only the BondingCurve contract can mint and burn these tokens
 */
contract Token is ERC20Burnable, Ownable {
    error Token_ZeroAddress();
    error Token_ZeroAmount();

    constructor(address initialOwner) ERC20("Token", "TKN") Ownable(initialOwner) {}

    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        _validateInput(to, amount);
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external onlyOwner returns (bool) {
        _validateInput(from, amount);
        _burn(from, amount);
        return true;
    }

    function _validateInput(address account, uint256 amount) internal pure {
        // Check if the account address is not a zero address
        if (account == address(0)) {
            revert Token_ZeroAddress();
        }
        // Check if the amount is not zero
        if (amount == 0) {
            revert Token_ZeroAmount();
        }
    }
}
