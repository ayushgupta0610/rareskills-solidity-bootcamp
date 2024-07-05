// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Vault is ERC4626 {

    constructor(IERC20 _asset, string memory _name, string memory _symbol) ERC4626(_asset) ERC20(_name, _symbol) {

    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 0;
    }

}