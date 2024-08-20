// SPDX-Licese-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "lib/solady/src/tokens/ERC20.sol";

contract Token is ERC20 {

    string private i_name;
    string private i_symbol;

    constructor(string memory _name, string memory _symbol) {
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

}