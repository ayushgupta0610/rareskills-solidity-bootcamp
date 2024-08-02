pragma solidity ^0.8.24;


interface IERC3156FlashLoanBorrower {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC3156FlashLoanLender {
    function maxFlashLoan(address token) external view returns (uint256);
    function flashFee(address token, uint256 amount) external view returns (uint256);
    function flashLoan(
        IERC3156FlashLoanBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}