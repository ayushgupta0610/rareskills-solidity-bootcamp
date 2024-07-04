// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Protect against reentrancy
// Protect against implementation logic update
// Protect against blacklist
// Protect against inflation/deflation
// Protect against double spend allowance / race approval token
contract UntrustedEscrow {
    using SafeERC20 for ERC20;

    error UntrustedEscrow_WaitTimeNotOver();
    error UntrustedEscrow_AlreadyDeposited();
    error UntrustedEscrow_NothingToWithdraw();

    ERC20 private token;

    // Emit events when the below state variables are updated?
    bool public isDeposited;
    uint256 public depositTime;
    address public seller;

    function depositFor(address _seller, address _token, uint256 _amount) external {
        if (isDeposited) {
            revert UntrustedEscrow_AlreadyDeposited();
        }
        depositTime = block.timestamp;
        token = ERC20(_token);
        seller = _seller;
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw() external {
        if (!isDeposited) {
            revert UntrustedEscrow_NothingToWithdraw();
        }
        if (block.timestamp < depositTime + 3 days) {
            revert UntrustedEscrow_WaitTimeNotOver();
        }
        isDeposited = false;
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(seller, amount);
    }

}