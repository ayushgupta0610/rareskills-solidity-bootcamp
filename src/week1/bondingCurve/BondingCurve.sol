// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface Token {
    function mint(address to, uint256 amount) external returns (bool);
    function burn(address from, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract BondingCurve is Ownable, ReentrancyGuard {
    // 1. Buy tokens from the protocol
    // 2. Sell tokens to the protocol
    // 3. Check for the price of buying x tokens
    // 4. Check the amount that would be received when trying to sell z tokens
    // 5. Check current liquidity available in the protocol
    // 6. Note: Take spread into account and the spread value received will go to the protocol
    // 7. Note (continued): Which then can be withdrawn by the admin of the protocol
    // 8. Note: To keep things simple you can take the price of the token to be linked with the ETH directly instead of the price of ETH (or any other token) in USD
    // 9. Note: Take care of the decimals while rounding off

    // Taking an assumption that the price of the xth token is y => y = 2x + 0 (slope defined as 2), How and why - not sure.
    // Taking an assumption that the price of the initial token is 1 gwei,

    error BondingCurve_TokenNotAllowed();
    error BondingCurve_ZeroAddress();
    error BondingCurve_ZeroAmount();
    error BondingCurve_InsufficientBalance();
    error BondingCurve_InsufficientFiatAmount(); // Fiat here being referred to the token with which the user can buy the token (ETH)
    error BondingCurve_NotEnoughLiquidity();

    Token private token;

    address immutable allowedToken;
    uint256 immutable initialPricePerToken; // One token has 18 decimals
    uint8 immutable TOKEN_DECIMAL;

    constructor(address _initialOwner, address _allowedToken, uint256 _initialPriceInWei) Ownable(_initialOwner) {
        if (_initialOwner == address(0) || _allowedToken == address(0)) {
            revert BondingCurve_ZeroAddress();
        }
        allowedToken = _allowedToken;
        token = Token(_allowedToken);
        initialPricePerToken = _initialPriceInWei; // Check for this
        TOKEN_DECIMAL = token.decimals();
    }

    // NOTE: timestamp/deadline aspect can be added to ensure that the user's txn cannot be frontrun
    // NOTE: min and max no of tokens that the user would receive can also be added
    function buyTokens(uint256 noOfTokens) external payable nonReentrant returns (uint256) {
        // Check for sufficient value deposited as the buy price for the number of tokens
        uint256 requiredValueToMintTokens = getBuyPriceForTokens(noOfTokens);
        if (msg.value < requiredValueToMintTokens) {
            revert BondingCurve_InsufficientFiatAmount();
        }
        uint256 noOfTokensToBeMinted = getNoOfTokensThatCanBeMintedWith(noOfTokens);
        token.mint(_msgSender(), noOfTokensToBeMinted);
        return noOfTokensToBeMinted;
    }

    // NOTE: timestamp/deadline aspect can be added to ensure that the user's txn cannot be frontrun
    // NOTE: min and max value that would be received by the user can also be added
    function sellTokens(uint256 noOfTokens) external returns (uint256) {
        // Check for sufficient value is received for the number of tokens burnt
        if (token.balanceOf(_msgSender()) < noOfTokens) {
            revert BondingCurve_InsufficientBalance();
        }
        token.burn(_msgSender(), noOfTokens);
        // Check if the protocol has enough liquidity / ether to pay back | Ideally it should to be a solvent protocol
        uint256 tokenValue = getValueToReceiveFromTokens(noOfTokens);
        if (tokenValue > address(this).balance) {
            revert BondingCurve_NotEnoughLiquidity();
        }
        return tokenValue;
    }

    // NOTE: Ensure the rounding happens in favor of the protocol
    function getTokenPriceInWei(address tokenAddress) external view returns (uint256) {
        // Calculate how many tokens have been minted and based on the same calculate the value of y, ie the price of the next token to be minted
        _validateInputToken(tokenAddress);
        // 1. Get total token supply and based on the same
        uint256 totalSupply = getTotalSupplyOfTokenMinted();
        if ((totalSupply * 2) % (10 ** TOKEN_DECIMAL) == 0) {
            return (totalSupply * 2) / (10 ** TOKEN_DECIMAL);
        }
        return (totalSupply * 2) / (10 ** TOKEN_DECIMAL) + 1;
    }

    // NOTE: Ensure the rounding happens in favor of the protocol
    // TODO: Variable name change and proper code commenting
    function getBuyPriceForTokens(uint256 noOfTokens) public view returns (uint256) {
        // Calculate the area of yx graph with x being the amount, ie the price of the next token to be minted
        uint256 totalSupply = getTotalSupplyOfTokenMinted();
        uint256 newX = totalSupply + noOfTokens;
        // Following the y = 2x equation to calculate the area under the curve / price
        uint256 priceAtNewX = 4 * (newX ** 2 - totalSupply ** 2);
        return priceAtNewX;
    }

    // NOTE: Ensure the rounding happens in favor of the protocol
    // TODO: Variable name change and proper code commenting
    function getSellPriceForTokens(uint256 noOfTokens) public view returns (uint256) {
        // Get the sell price for the tokens
        // In second iteration, take into account the spread for protocol
        uint256 totalSupply = getTotalSupplyOfTokenMinted();
        uint256 newX = totalSupply - noOfTokens;
        // Following the y = 2x equation to calculate the area under the curve / price
        uint256 priceAtNewX = 4 * (totalSupply ** 2 - newX ** 2);
        return priceAtNewX;
    }

    // NOTE: Ensure the rounding happens in favor of the protocol
    function getNoOfTokensThatCanBeMintedWith(uint256 value) public view returns (uint256) {
        // uint256 reserveTokenRate =
    }

    // NOTE: Ensure the rounding happens in favor of the protocol
    function getValueToReceiveFromTokens(uint256 noOfTokens) public view returns (uint256) {
        // uint256 reserveTokenRate =
    }

    function getCurrentLiquidity() external view returns (uint256) {
        // Get the amount of ETH deposited in the protocol
    }

    function getTotalSupplyOfTokenMinted() public view returns (uint256) {
        return token.totalSupply();
    }

    function withdrawFiatBalance() external nonReentrant onlyOwner {
        // Calculate how much should be the amount that the owner can withdraw
    }

    function _validateInputToken(address tokenAddress) internal view {
        if (tokenAddress != allowedToken) {
            revert BondingCurve_TokenNotAllowed();
        }
    }
}
