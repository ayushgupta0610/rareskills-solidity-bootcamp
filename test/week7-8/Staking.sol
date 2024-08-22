// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import "../src/MerkleDistributor.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// contract MerkleDistributorTest is Test {
//     MerkleDistributor public distributor;
//     IERC20 public token;

//     bytes32 public constant MERKLE_ROOT = 0x5b2c51cfdad30d509d4b0f72097d20d2fc25fc3453a99b8e9f02d49745428cab; // Example root, you should calculate this

//     function setUp() public {
//         // Deploy your token contract here or use a mock
//         token = IERC20(address(new MockERC20())); 
//         distributor = new MerkleDistributor(address(token), MERKLE_ROOT);
//     }

//     function testClaim() public {
//         uint256 index = 0;
//         address account = address(0x1111111111111111111111111111111111111111);
//         uint256 amount = 1000000000000000000;
//         bytes32[] memory proof = new bytes32[](3);
//         proof[0] = bytes32(0x0a3a1a2d07b3a2f7e40f7b382f46c4e51e68b75072d4fc12d4562201d3a9169c);
//         proof[1] = bytes32(0xccbc75cfde90ee1a9f6a97c7a8b35ae74ce25d5e55149efca05f6c049a3e580a);
//         proof[2] = bytes32(0xc8c0a561572a5cb6a72ecf97326ffbe54a8579cdf89af5cbed719d6703d2ad33);

//         // Ensure the token has enough balance
//         deal(address(token), address(distributor), amount);

//         // Perform the claim
//         distributor.claim(index, account, amount, proof);

//         // Assert the claim was successful
//         assertEq(token.balanceOf(account), amount);
//         assertTrue(distributor.isClaimed(index));
//     }
// }

// // Mock ERC20 token for testing
// contract MockERC20 is IERC20 {
//     mapping(address => uint256) private _balances;
//     mapping(address => mapping(address => uint256)) private _allowances;
//     uint256 private _totalSupply;

//     function totalSupply() external view override returns (uint256) {
//         return _totalSupply;
//     }

//     function balanceOf(address account) external view override returns (uint256) {
//         return _balances[account];
//     }

//     function transfer(address recipient, uint256 amount) external override returns (bool) {
//         _transfer(msg.sender, recipient, amount);
//         return true;
//     }

//     function allowance(address owner, address spender) external view override returns (uint256) {
//         return _allowances[owner][spender];
//     }

//     function approve(address spender, uint256 amount) external override returns (bool) {
//         _approve(msg.sender, spender, amount);
//         return true;
//     }

//     function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
//         _transfer(sender, recipient, amount);
//         uint256 currentAllowance = _allowances[sender][msg.sender];
//         require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
//         unchecked {
//             _approve(sender, msg.sender, currentAllowance - amount);
//         }
//         return true;
//     }

//     function _transfer(address sender, address recipient, uint256 amount) internal {
//         require(sender != address(0), "ERC20: transfer from the zero address");
//         require(recipient != address(0), "ERC20: transfer to the zero address");
//         uint256 senderBalance = _balances[sender];
//         require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
//         unchecked {
//             _balances[sender] = senderBalance - amount;
//         }
//         _balances[recipient] += amount;
//         emit Transfer(sender, recipient, amount);
//     }

//     function _approve(address owner, address spender, uint256 amount) internal {
//         require(owner != address(0), "ERC20: approve from the zero address");
//         require(spender != address(0), "ERC20: approve to the zero address");
//         _allowances[owner][spender] = amount;
//         emit Approval(owner, spender, amount);
//     }
// }