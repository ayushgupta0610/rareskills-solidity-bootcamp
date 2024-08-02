// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "lib/solady/src/tokens/ERC20.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {UQ112x112} from "./libraries/UQ112x112.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IERC3156FlashLoanBorrower, IERC3156FlashLoanLender} from "./interfaces/IFlashLoanLender.sol";
import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";
import {ReentrancyGuard} from "lib/solady/src/utils/ReentrancyGuard.sol";
import {SafeTransferLib} from "lib/solady/src/utils/SafeTransferLib.sol";

contract UniswapV2Pair is ERC20, IERC3156FlashLoanLender, ReentrancyGuard {

    //////////////////////////////
    // Errors
    //////////////////////////////
    error UniswapV2Pair__FORBIDDEN();
    error UniswapV2Pair__OVERFLOW();
    error UniswapV2Pair__INSUFFICIENT_LIQUIDITY_MINTED();
    error UniswapV2Pair__INSUFFICIENT_LIQUIDITY_BURNED();
    error UniswapV2Pair__INSUFFICIENT_OUTPUT_AMOUNT();
    error UniswapV2Pair__INSUFFICIENT_LIQUIDITY();
    error UniswapV2Pair__INVALID_TO();
    error UniswapV2Pair__INSUFFICIENT_INPUT_AMOUNT();
    error UniswapV2Pair__K();
    error UniswapV2Pair__TRANSFER_FAILED();
    error UniswapV2Pair__NOT_ENOUGH_BALANCE();
    error UniswapV2Pair__INVALID_CALLBACK_RETURN();


    //////////////////////////////
    // Type
    //////////////////////////////
    using UQ112x112 for uint;
    using FixedPointMathLib for uint;
    using SafeTransferLib for address;

    //////////////////////////////
    // State Variables
    //////////////////////////////
    string private constant NAME = 'Uniswap V2';
    string private constant SYMBOL = 'UNI-V2';
    uint public constant FLASH_LOAN_FEE = 90000; // 0.09%
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event


    //////////////////////////////
    // Events
    //////////////////////////////
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        if (msg.sender != factory) {
            revert UniswapV2Pair__FORBIDDEN();
        }
        token0 = _token0;
        token1 = _token1;
    }

     // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        if (!(balance0 <= type(uint112).max && balance1 <= type(uint112).max)) {
            revert UniswapV2Pair__OVERFLOW();
        }
        unchecked {
            uint32 blockTimestamp = uint32(block.timestamp % 2**32);
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                // * never overflows, and + overflow is desired | TODO: Uncomment this
                // price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
                // price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
                price0CumulativeLast = 0;
                price1CumulativeLast = 0;
            }
            reserve0 = uint112(balance0);
            reserve1 = uint112(balance1);
            blockTimestampLast = blockTimestamp;
        }
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = FixedPointMathLib.sqrt(uint(_reserve0).mulWad(_reserve1));
                uint rootKLast = FixedPointMathLib.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply().mulWad(rootK - rootKLast);
                    uint denominator = rootK.mulWad(5) - rootKLast;
                    uint liquidity = numerator.divWad(denominator);
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to, uint amount0, uint amount1) external nonReentrant returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = _token0.balanceOf(address(this));
        uint balance1 = _token1.balanceOf(address(this));
        // uint amount0 = balance0 - _reserve0;
        // uint amount1 = balance1 - _reserve1;
        _token0.safeTransferFrom(msg.sender, address(this), amount0);
        _token1.safeTransferFrom(msg.sender, address(this), amount1);
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = FixedPointMathLib.sqrt(amount0.mulWad(amount1)) - MINIMUM_LIQUIDITY;
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = FixedPointMathLib.min((amount0.mulWad(_totalSupply)).divWad(_reserve0), (amount1.mulWad(_totalSupply)).divWad(_reserve1));
        }
        if (liquidity < 0) {
            revert UniswapV2Pair__INSUFFICIENT_LIQUIDITY_MINTED();
        }
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mulWad(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to, uint liquidity) external nonReentrant returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = _token0.balanceOf(address(this));
        uint balance1 = _token1.balanceOf(address(this));
        // uint liquidity = balanceOf(address(this));
        address(this).safeTransferFrom(msg.sender, address(this), liquidity);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (liquidity.mulWad(balance0)).divWad(_totalSupply); // using balances ensures pro-rata distribution
        amount1 = (liquidity.mulWad(balance1)).divWad(_totalSupply); // using balances ensures pro-rata distribution
        if (!(amount0 > 0 && amount1 > 0)) {
            revert UniswapV2Pair__INSUFFICIENT_LIQUIDITY_BURNED();
        }
        _burn(address(this), liquidity);
        _token0.safeTransfer(to, amount0);
        _token1.safeTransfer(to, amount1);
        balance0 = _token0.balanceOf(address(this));
        balance1 = _token1.balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mulWad(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address to) external nonReentrant {
        if(!(amount0Out > 0 || amount1Out > 0)) {
            revert UniswapV2Pair__INSUFFICIENT_OUTPUT_AMOUNT();
        }
        if (!(amount0In > 0 || amount1In > 0)) {
            revert UniswapV2Pair__INSUFFICIENT_INPUT_AMOUNT();
        }
        address _token0 = token0;
        address _token1 = token1;
        _token0.safeTransferFrom(msg.sender, address(this), amount0In);
        _token1.safeTransferFrom(msg.sender, address(this), amount1In);
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        if (!(amount0Out < _reserve0 && amount1Out < _reserve1)) {
            revert UniswapV2Pair__INSUFFICIENT_LIQUIDITY();
        }
        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            if (!(to != _token0 && to != _token1)) {
                revert UniswapV2Pair__INVALID_TO();
            }
            if (amount0Out > 0) _token0.safeTransfer(to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _token1.safeTransfer(to,amount1Out); // optimistically transfer tokens
            balance0 = _token0.balanceOf(address(this));
            balance1 = _token1.balanceOf(address(this));
        }
        uint amount0In;
        uint amount1In;
        // unchecked {
        //     amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        //     amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        // }
        // if (!(amount0In > 0 || amount1In > 0)) {
        //     revert UniswapV2Pair__INSUFFICIENT_INPUT_AMOUNT();
        // }
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0.mulWad(1000) - amount0In.mulWad(3);
            uint balance1Adjusted = balance1.mulWad(1000) - amount1In.mulWad(3);
            if (!(balance0Adjusted.mulWad(balance1Adjusted) >= uint(_reserve0).mulWad(_reserve1).mulWad(1000**2))) {
                revert UniswapV2Pair__K();
            }
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _token0.safeTransfer(to, _token0.balanceOf(address(this)) - reserve0);
        _token1.safeTransfer(to, _token1.balanceOf(address(this)) - reserve1);
    }

    // force reserves to match balances
    function sync() external nonReentrant {
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)), reserve0, reserve1);
    }

    function name() public view override returns (string memory) {
        return NAME;
    }

    function symbol() public view override returns (string memory) {
        return SYMBOL;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function maxFlashLoan(address token) external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        return (amount.mulWad(FLASH_LOAN_FEE)).divWad(100000);
    }

    function flashLoan(
        IERC3156FlashLoanBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override nonReentrant returns (bool) {
        if (amount > token.balanceOf(address(this))) {
            revert UniswapV2Pair__NOT_ENOUGH_BALANCE();
        }
        uint256 _fee = flashFee(token, amount);
        token.safeTransfer(address(receiver), amount);

        if (receiver.onFlashLoan(msg.sender, token, amount, _fee, data) != CALLBACK_SUCCESS) {
            revert UniswapV2Pair__INVALID_CALLBACK_RETURN();
        }

        token.safeTransferFrom(address(receiver), address(this), amount + _fee);

        return true;
    }
}