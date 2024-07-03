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
    // mapping(address => bool) private isBlacklisted;
    mapping(address => uint256) private isBlacklisted;

    // Define the role for the admin
    bytes32 public constant ADMIN = keccak256("ADMIN");

    event Blacklist(address account, bool isBlacklisted);

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

    // Feedback: Since in each transfer function this is being checked, cast and uncast would add to the gas
    // function setBlacklist(address account, bool _isBlacklisted) external onlyAdmin {
    //     isBlacklisted[account] = _isBlacklisted;
    // }

    // Feedback: Since in each transfer function this is being checked, cast and uncast would add to the gas
    // function isBlacklistedAccount(address account) external view returns (bool) {
    //     return isBlacklisted[account];
    // }

    function setBlacklist(address account, uint256 _isBlacklisted) external onlyAdmin {
        emit Blacklist(account, _isBlacklisted>0);
        isBlacklisted[account] = _isBlacklisted;
    }

    function isBlacklistedAccount(address account) external view returns (bool) {
        return isBlacklisted[account]>0;
    }

    // function transfer(address recipient, uint256 amount) public override returns (bool) {
    //     if (isBlacklisted[_msgSender()]) {
    //         revert TokenWithSanctions__SenderIsBlacklisted();
    //     }
    //     if (isBlacklisted[recipient]) {
    //         revert TokenWithSanctions__RecipientIsBlacklisted();
    //     }
    //     return super.transfer(recipient, amount);
    // }

    // Feedback: Instead of the above function as well as transferFrom function (which was missed), we can override the _update function alone
    function _update(address from, address to, uint256 value) internal override {
        if (isBlacklisted[from]>0) {
            revert TokenWithSanctions__SenderIsBlacklisted();
        }
        if (isBlacklisted[to]>0) {
            revert TokenWithSanctions__RecipientIsBlacklisted();
        }
        return super._update(from, to, value);
    }
}
