// SPDX-Licese-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "lib/solady/src/tokens/ERC20.sol";
import {Ownable} from "lib/solady/src/auth/Ownable.sol";

contract RewardsToken is ERC20, Ownable {

    string private i_name;
    string private i_symbol;

    constructor(string memory _name, string memory _symbol) {
        _initializeOwner(msg.sender);
        i_name = _name;
        i_symbol = _symbol;
    }

    /// @dev Returns the name of the token.
    function name() public view override returns (string memory) {
        return i_name;
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return i_symbol;
    }

    function mint(address to, uint256 amount) external onlyOwner {
         _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    // Withdraw locked ethers
    function withddraw() external onlyOwner {
        (bool success, ) = owner().call{ value: (address(this).balance) }("");
        require(success, "RewardsToken: withdraw failed");
    }
}