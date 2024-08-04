## Advanced Solidity Bootcamp

**Week 1**

Reading Material:


Practise Exercises:

-   **TokenWithSanctions.sol**: a fungible token that allows an admin to ban specified addresses from sending and receiving tokens
-   **TokenWithGodMode.sol**: A special address is able to transfer tokens between addresses at will.
-   **BondingCurve.sol**: Token sale and buyback with bonding curve. The more tokens a user buys, the more expensive the token becomes. (linear bonding curve)
-   **UntrustedEscrow.sol**: A contract where a buyer can put an arbitrary ERC20 token into a contract and a seller can withdraw it 3 days later

Week 3, 4, 5 exercises were to complete UniswapV2 puzzles [https://github.com/RareSkills/uniswap-v2-puzzles]

Week 6 - Re-implement Uniswap V2 with the following requirements
- use solidity 0.8.0 or higher. **You need to be conscious of when the original implementation originally intended to overflow in the oracle**
- Use the Solady ERC20 library to accomplish the LP token, also use the Solady library to accomplish the square root
- The uniswap re-entrancy lock is not gas efficient anymore because of changes in the EVM
- Your code should have built-in safety checks for swap, mint, and burn. **You should not assume people will use a router but instead directly interface with your contract**
- The swap function should not support flash swaps, you should build a separate flashloan function that is compliant with ERC-3156
- Don’t use safemath with 0.8.0 or higher
- You should only implement the factory and the pair (which inherits from ERC20), don’t implement other contracts