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
    // 1. Note: Take spread into account and the spread value received will go to the protocol
    // 2. Note (continued): Which then can be withdrawn by the admin of the protocol

    // Taking an assumption that the price of the xth token is y => y = 2x + 0 (slope defined as 2)

    error BondingCurve_ZeroAddress();
    error BondingCurve_ZeroAmount();
    error BondingCurve_InsufficientBalance();
    error BondingCurve_InsufficientFiatAmount(); // Fiat here being referred to the token with which the user can buy the token (ETH)
    error BondingCurve_NotEnoughLiquidity();
    error BondingCurve_TransferFailed();

    Token private token;

    uint8 immutable TOKEN_DECIMAL;

    constructor(address _initialOwner, address _allowedToken) Ownable(_initialOwner) {
        if (_initialOwner == address(0) || _allowedToken == address(0)) {
            revert BondingCurve_ZeroAddress();
        }
        token = Token(_allowedToken);
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
        // return the left over msg.value to the user
        uint256 remainingValue = requiredValueToMintTokens - msg.value;
        if (remainingValue > 0) {
            (bool success,) = _msgSender().call{value: remainingValue}("");
            if (!success) revert BondingCurve_TransferFailed();
        }
        token.mint(_msgSender(), noOfTokens);
        return remainingValue;
    }

    // NOTE: timestamp/deadline aspect can be added to ensure that the user's txn cannot be frontrun
    // NOTE: min and max value that would be received by the user can also be added
    function sellTokens(uint256 noOfTokens) external nonReentrant returns (uint256) {
        // Check for sufficient value is received for the number of tokens burnt
        if (token.balanceOf(_msgSender()) < noOfTokens) {
            revert BondingCurve_InsufficientBalance();
        }
        // Check if the protocol has enough liquidity / ether to pay back | Ideally it should to be a solvent protocol
        uint256 tokenValue = getValueToReceiveFromTokens(noOfTokens);
        if (tokenValue > address(this).balance) {
            revert BondingCurve_NotEnoughLiquidity();
        }
        token.burn(_msgSender(), noOfTokens); // This saves one transferFrom operation | or would two separate transactions be better?
        (bool success,) = _msgSender().call{value: tokenValue}("");
        if (!success) revert BondingCurve_TransferFailed();
        return tokenValue;
    }

    // TODO: Variable name change and proper code commenting
    function getBuyPriceForTokens(uint256 noOfTokens) public view returns (uint256 buyPriceForTokens) {
        // Calculate the area of yx graph with x being the amount, ie the price of the next token to be minted
        uint256 totalSupply = getTotalSupplyOfTokenMinted();
        uint256 supplyAfterBuying = totalSupply + noOfTokens;
        // Following the y = 2x equation to calculate the area under the curve / price
        buyPriceForTokens = (supplyAfterBuying ** 2 - totalSupply ** 2) / 10 ** TOKEN_DECIMAL;
    }

    // TODO: Variable name change and proper code commenting
    function getSellPriceForTokens(uint256 noOfTokens) public view returns (uint256 sellPriceForTokens) {
        // Get the sell price for the tokens
        // In second iteration, take into account the spread for protocol
        uint256 totalSupply = getTotalSupplyOfTokenMinted();
        uint256 supplyAfterSelling = totalSupply - noOfTokens;
        // Following the y = 2x equation to calculate the area under the curve / price
        sellPriceForTokens = (totalSupply ** 2 - supplyAfterSelling ** 2) / 10 ** TOKEN_DECIMAL;
    }

    // function getNoOfTokensThatCanBeMintedWith(uint256 value) public view returns (uint256) {}

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

    // function withdrawDust() external nonReentrant onlyOwner {
    //     // Calculate how much should be the amount that the owner can withdraw
    //     uint256 withdrawableAmount = address(this).balance; // CHECK THIS: Not a decentralised protocol if this is there
    //     (bool success,) = owner().call{value: withdrawableAmount}("");
    //     if (!success) revert BondingCurve_TransferFailed();
    // }

}
