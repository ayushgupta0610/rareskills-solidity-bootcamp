// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Token with sanctions
 *     @author Ayush Gupta
 *     @dev This contract is a fungible ERC20 token that allows an admin to ban specified addresses from sending and receiving tokens
 *     @notice Only the admin can blacklist addresses
 */
contract TokenWithSanctions is ERC20, AccessControl {
    error TokenWithSanctions__RestrictedToAdmins();
    error TokenWithSanctions__RecipientIsBlacklisted();
    error TokenWithSanctions__SenderIsBlacklisted();

    // Disable transfer option for blacklist addresses; the control of the which should be with the admin
    mapping(address => bool) private isBlacklisted;

    // Define the role for the admin
    bytes32 public constant ADMIN = keccak256("ADMIN");

    modifier onlyAdmin() {
        if (hasRole(ADMIN, _msgSender())) {
            _;
        } else {
            revert TokenWithSanctions__RestrictedToAdmins();
        }
    }

    constructor(address admin, string memory name, string memory symbol) ERC20(name, symbol) {
        _grantRole(ADMIN, admin);
        _mint(admin, 1000000 ether); // As token decimal is standardised to 18
    }

    function setBlacklist(address account, bool _isBlacklisted) external onlyAdmin {
        isBlacklisted[account] = _isBlacklisted;
    }

    function isBlacklistedAccount(address account) external view returns (bool) {
        return isBlacklisted[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (isBlacklisted[_msgSender()]) {
            revert TokenWithSanctions__SenderIsBlacklisted();
        }
        if (isBlacklisted[recipient]) {
            revert TokenWithSanctions__RecipientIsBlacklisted();
        }
        return super.transfer(recipient, amount);
    }
}
