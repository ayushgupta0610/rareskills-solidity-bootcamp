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

    ERC20 private token;

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

    function withdraw(uint256 _amount) external {
        if (block.timestamp < depositTime + 3 days) {
            revert UntrustedEscrow_WaitTimeNotOver();
        }
        token.safeTransfer(seller, _amount);
    }

}