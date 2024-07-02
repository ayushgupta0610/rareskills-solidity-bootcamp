// SPDX-License-Identifier
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 *     @title Token with god mode
 *     @author Ayush Gupta
 *     @dev This contract is a special ERC20 token that allows a special address (god) to transfer tokens between addresses at will
 *     @notice Only the god address can transfer tokens between addresses
 */
contract TokenWithGodMode is ERC20, AccessControl {
    error TokenWithGodMode__RestrictedToGod();

    // Define the role for the god
    bytes32 public constant GOD = keccak256("GOD");

    modifier onlyGod() {
        if (hasRole(GOD, _msgSender())) {
            _;
        } else {
            revert TokenWithGodMode__RestrictedToGod();
        }
    }

    constructor(address god, string memory name, string memory symbol) ERC20(name, symbol) {
        _grantRole(GOD, god);
    }

    function transfer(address sender, address recipient, uint256 amount) external onlyGod returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }
}
