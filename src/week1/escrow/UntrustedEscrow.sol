// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Protect against reentrancy - Done
// Protect against implementation logic update - Done
// Protect against inflation/deflation - Done
contract UntrustedEscrow is ReentrancyGuard {
    using SafeERC20 for ERC20;

    error UntrustedEscrow_WaitTimeNotOver();
    error UntrustedEscrow_AlreadyDeposited();
    error UntrustedEscrow_NothingToWithdraw();
    error UntrustedEscrow_InsufficientFundsTransferred();

    ERC20 private token;

    // Emit events when the below state variables are updated?
    bool public isDeposited;
    uint256 public depositTime;
    address public seller;

    function depositFor(address _seller, address _token, uint256 _amount) external nonReentrant {
        uint256 initialBalance = token.balanceOf(address(this));
        if (isDeposited) {
            revert UntrustedEscrow_AlreadyDeposited();
        }
        isDeposited = true;
        depositTime = block.timestamp;
        token = ERC20(_token);
        seller = _seller;
        token.safeTransferFrom(msg.sender, address(this), _amount);
        if (initialBalance + _amount <= token.balanceOf(address(this))) {
            revert UntrustedEscrow_InsufficientFundsTransferred();
        }
    }

    function withdraw() external nonReentrant {
        uint256 initialBalance = token.balanceOf(address(this));
        if (!isDeposited) {
            revert UntrustedEscrow_NothingToWithdraw();
        }
        if (block.timestamp < depositTime + 3 days) {
            revert UntrustedEscrow_WaitTimeNotOver();
        }
        isDeposited = false;
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(seller, amount);
        if (initialBalance - amount != token.balanceOf(address(this))) {
            revert UntrustedEscrow_InsufficientFundsTransferred();
        }
    }

}