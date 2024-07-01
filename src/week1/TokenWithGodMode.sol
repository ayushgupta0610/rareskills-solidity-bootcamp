// SPDX-License-Identifier
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 *     @title Token with god mode
 *     @author Ayush Gupta
 *     @dev This contract is a special ERC20 token that allows a special address (admin/god) to transfer tokens between addresses at will
 *     @notice Only the admin/god can transfer tokens between addresses
 */
contract TokenWithGodMode is ERC20, AccessControl {
    error TokenWithGodMode__RestrictedToAdmin();

    // Define the role for the admin/god
    bytes32 public constant ADMIN = keccak256("ADMIN");

    modifier onlyAdmin() {
        if (hasRole(ADMIN, _msgSender())) {
            _;
        } else {
            revert TokenWithGodMode__RestrictedToAdmin();
        }
    }

    constructor(address admin, string memory name, string memory symbol) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function transfer(address sender, address recipient, uint256 amount) external onlyAdmin returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }
}
