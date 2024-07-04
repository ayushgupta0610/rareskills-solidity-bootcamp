// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface Token {
    function mint(address to, uint256 amount) external returns (bool);
    function burn(address from, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract BondingCurve is Ownable2Step, ReentrancyGuard {
    // 1. Note: Take spread into account and the spread value received will go to the protocol
    // 2. Note (continued): Which then can be withdrawn by the admin of the protocol

    // Taking an assumption that the price of the xth token is y => y = 2x + 0 (slope defined as 2)

    error BondingCurve_ZeroAddress();
    error BondingCurve_InsufficientBalance();
    error BondingCurve_InsufficientFiatAmount(); // Fiat here being referred to the token with which the user can buy the token (ETH)
    error BondingCurve_NotEnoughLiquidity();
    error BondingCurve_TransferFailed();
    error BondingCurve_InsufficientTokenValue();
    error BondingCurve_TradeExpired();

    Token private token;

    uint8 immutable TOKEN_DECIMAL;

    modifier ensureDeadline(uint256 deadline) {
        if (block.timestamp > deadline) {
            revert BondingCurve_TradeExpired();
        }
        _;
    }

    constructor(address _initialOwner, address _allowedToken) Ownable(_initialOwner) {
        if (_initialOwner == address(0) || _allowedToken == address(0)) {
            revert BondingCurve_ZeroAddress();
        }
        token = Token(_allowedToken);
        TOKEN_DECIMAL = token.decimals();
    }

    function buyTokens(uint256 noOfTokens, uint256 minTokens, uint256 deadline) external payable ensureDeadline(deadline) nonReentrant returns (uint256) {
        // Check for sufficient value deposited as the buy price for the number of tokens
        uint256 requiredValueToMintTokens = getBuyPriceForTokens(noOfTokens);
        if (msg.value < requiredValueToMintTokens) {
            revert BondingCurve_InsufficientFiatAmount();
        }
        uint256 tokensToBuy = getNoOfTokensThatCanBeMintedWith(msg.value);
        if (tokensToBuy < minTokens) {
            revert BondingCurve_InsufficientFiatAmount();
        }
        // return the left over msg.value to the user
        uint256 remainingValue = requiredValueToMintTokens - msg.value;
        if (remainingValue > 0) {
            (bool success,) = _msgSender().call{value: remainingValue}("");
            if (!success) revert BondingCurve_TransferFailed();
        }
        token.mint(_msgSender(), noOfTokens);
        return remainingValue;
    }

    function sellTokens(uint256 noOfTokens, uint256 minValue, uint256 deadline) external ensureDeadline(deadline) nonReentrant returns (uint256) {
        // Check if sufficient value is received for the number of tokens burnt
        if (token.balanceOf(_msgSender()) < noOfTokens) {
            revert BondingCurve_InsufficientBalance();
        }
        // Check if the protocol has enough liquidity / ether to pay back | Ideally it should to be a solvent protocol
        uint256 tokenValue = getValueToReceiveFromTokens(noOfTokens);
        if (tokenValue > address(this).balance) {
            revert BondingCurve_NotEnoughLiquidity();
        }
        if (tokenValue < minValue) {
            revert BondingCurve_InsufficientTokenValue();
        }
        token.burn(_msgSender(), noOfTokens); // This saves one transferFrom operation | or would two separate transactions be better?
        (bool success,) = _msgSender().call{value: tokenValue}("");
        if (!success) revert BondingCurve_TransferFailed();
        return tokenValue;
    }

    function getBuyPriceForTokens(uint256 noOfTokens) public view returns (uint256 buyPriceForTokens) {
        // Calculate the area of yx graph with x being the amount, ie the price of the next token to be minted
        uint256 totalSupply = getTotalSupplyOfTokenMinted();
        uint256 supplyAfterBuying = totalSupply + noOfTokens;
        // Following the y = 2x equation to calculate the area under the curve / price
        buyPriceForTokens = (supplyAfterBuying ** 2 - totalSupply ** 2) / 10 ** TOKEN_DECIMAL;
    }

    function getNoOfTokensThatCanBeMintedWith(uint256 value) public view returns (uint256) {
        uint256 totalSupply = getTotalSupplyOfTokenMinted();
        uint256 currentPrice = 2 * totalSupply;
        if (currentPrice>value) return 0;
        // Following: y = 2x + 0 and the value provided being the area of the new triangle, we need to find out sqrt(totalSupply**2 + value) - totalSupply
        uint256 sqOfTokens = totalSupply ** 2 - value;
        return sqrt(sqOfTokens) - totalSupply;
    }

    function getValueToReceiveFromTokens(uint256 noOfTokens) public view returns (uint256 value) {
        uint256 totalSupply = getTotalSupplyOfTokenMinted();
        if (totalSupply < noOfTokens) {
            revert BondingCurve_NotEnoughLiquidity();
        }
        uint256 supplyAfterSelling = totalSupply - noOfTokens;
        value = (totalSupply ** 2 - supplyAfterSelling ** 2) / 10 ** TOKEN_DECIMAL;
    }

    // Get the amount of ETH deposited in the protocol
    function getCurrentLiquidity() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalSupplyOfTokenMinted() public view returns (uint256) {
        return token.totalSupply();
    }

    function sqrt(uint256 x) public pure returns (uint256 result) {
        assembly {
            // Start by checking if the input is zero.
            // If so, the result is also zero.
            switch x
            case 0 {
                result := 0
            }
            default {
                // Use the Babylonian method to approximate the square root.
                let z := x
                let y := div(add(z, 1), 2)
                for { } gt(z, y) { } {
                    z := y
                    y := div(add(div(x, y), y), 2)
                }
                result := z
            }
        }
    }
}
