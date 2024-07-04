// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 *     @title Token contract with limitless supply
 *     @author Ayush Gupta
 *     @dev This contract is a token contract that can be minted and burned by
 *     @notice Only the BondingCurve contract can mint and burn these tokens
 */
contract Token is ERC20Burnable, Ownable {
    error Token_ZeroAmount();

    // Ownership transfer would be required to BondingCurve contract
    constructor(address initialOwner) ERC20("Token", "TKN") Ownable(initialOwner) {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        _validateInput(amount);
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external onlyOwner returns (bool) {
        _validateInput(amount);
        _burn(from, amount);
        return true;
    }

    function _validateInput(uint256 amount) internal pure {
        // Check if the amount is not zero
        if (amount == 0) {
            revert Token_ZeroAmount();
        }
    }
}
