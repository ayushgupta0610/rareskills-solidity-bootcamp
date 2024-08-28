const { MerkleTree } = require("merkletreejs");
const ethers = require("ethers");
const keccak256 = require("keccak256");

// inputs: array of users' addresses and quantity
// each item in the inputs array is a block of data
// Alice, Bob and Carol's data respectively
const inputs = [
  {
    address: "0x47d1111fec887a7beb7839bbf0e1b3d215669d86",
    quantity: 1, // Assuming a default quantity of 1 for each address
  },
  {
    address: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
    quantity: 1, // Adjust quantity as needed
  },
  {
    address: "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
    quantity: 1,
  },
  {
    address: "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc",
    quantity: 1,
  },
  {
    address: "0x90f79bf6eb2c4f870365e785982e1f101e93b906",
    quantity: 1,
  },
  {
    address: "0x15d34aaf54267db7d7c367839aaf71a00a2c6a65",
    quantity: 1,
  },
];

// create leaves from users' address and quantity
const leaves = inputs.map((input) =>
  ethers.utils.solidityKeccak256(
    ["address", "uint256"],
    [input.address, input.quantity]
  )
);
// create a Merkle tree
const tree = new MerkleTree(leaves, keccak256, { sort: true });
console.log(tree.toString());

// can you give me the merkle proof for the address 0x47d1111fec887a7beb7839bbf0e1b3d215669d86?
const proof = tree.getProof(leaves[0]);
console.log("Tree root: ", tree.getHexRoot());
const proofHex = proof.map((p) => ethers.utils.hexlify(p.data));
console.log(`Proof for address ${inputs[0].address}: `, proofHex);
