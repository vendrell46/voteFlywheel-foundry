//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/MultiMerkleDistributorV2.sol";
import "../src/MockCreator.sol";
import "../src/MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Merkle} from "./murky/Merkle.sol";


contract MultiMerkleDistributorV2Test is Test {

    MultiMerkleDistributorV2 distributor;
    MockCreator lootCreator;
    MockERC20 token;
    IERC20 CRV;
    IERC20 DAI;

    address admin;
    address mockQuestBoard;
    address[] users;

    // Token addresses for CRV and DAI - replace with actual addresses if needed
    address constant TOKEN1_ADDRESS = 0xD533a949740bb3306d119CC777fa900bA034cd52; // CRV
    address constant TOKEN2_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI

    // Holder addresses for CRV and DAI - replace with actual addresses or remove if not needed
    address constant BIG_HOLDER1 = 0xF977814e90dA44bFA03b6295A0616a897441aceC; // CRV holder
    address constant BIG_HOLDER2 = 0x075e72a5eDf65F0A5f44699c7654C1a76941Ddc8; // DAI holder

    uint256 private constant WEEK = 604800;
    address public immutable userA = makeAddr("userA");
    address public immutable userB = makeAddr("userB");
    bytes32[] public userA_PROOF_2;
    bytes32[] public userB_PROOF_2;



    function setUp() public {
        token = new MockERC20("Test Token", "TT");
        admin = address(this);
        mockQuestBoard = address(1); // Mock address for the quest board

        // Deploy the MultiMerkleDistributorV2 contract
        distributor = new MultiMerkleDistributorV2(mockQuestBoard);
        token.mint(address(distributor), 600 ether);

        // Deploy the MockCreator contract
        lootCreator = new MockCreator(admin);

        // Initialize ERC20 tokens
        CRV = IERC20(TOKEN1_ADDRESS);
        DAI = IERC20(TOKEN2_ADDRESS);

        // Set up users - these could be any addresses
        users.push(address(2));
        users.push(address(3));
        users.push(address(4));
        users.push(address(5));
    }

    // function testClaimIssue() public {
    //     // User A's address and claimable amount
    //     address userA = address(1);
    //     uint256 claimableAmount = 500 ether;

    //     // Create data for a new Merkle tree
    //     bytes32[] memory leafNodes = new bytes32[](1);
    //     leafNodes[0] = keccak256(abi.encodePacked(userA, claimableAmount));

    //     // Generate a new valid Merkle root. Use a simple mock or a utility contract if needed
    //     bytes32 merkleRoot = keccak256(abi.encodePacked(leafNodes[0]));

    //     // Setup the distributor: Add quest, set merkle root, etc.
    //     // Assuming questID and period are predefined or set up earlier
    //     uint256 questID = 1;
    //     uint256 period = block.timestamp;
    //     distributor.addQuest(questID, address(token));
    //     distributor.updateQuestPeriod(questID, period, claimableAmount, merkleRoot);

    //     // Attempt to claim with 0 amount (to simulate the suspected issue)
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = leafNodes[0]; // Simplified proof, in reality, you'd construct a valid Merkle proof for the claim

    //     vm.prank(userA);
    //     distributor.claim(questID, period, 0, userA, 0, proof); // Claim with 0 amount

    //     // Now, attempt to claim the actual amount
    //     vm.prank(userA);
    //     vm.expectRevert("AlreadyClaimed"); // Expecting this revert based on the suspected issue
    //     distributor.claim(questID, period, 0, userA, claimableAmount, proof); // Attempt to claim the correct amount
    // }


function test_reClaimIssue() public {

    uint256 claimableAmount = 500 ether;
    uint256 questID = 1;
    uint256 period = (block.timestamp / WEEK) * WEEK + WEEK;
    uint256 index = 0; // Asegura que el periodo comience al inicio de la próxima semana

    uint256 claimableAmount2 = 100 ether;
    uint256 questID2 = 2;
    uint256 period2 = (block.timestamp / WEEK) * WEEK + WEEK;
    uint256 index2 = 1; // Asegura que el periodo comience al inicio de la próxima semana

    Merkle m = new Merkle();
    bytes32[] memory leafNodes = new bytes32[](2);
    leafNodes[0] = keccak256(abi.encodePacked(questID,period, index, userA, claimableAmount));
    leafNodes[1] = keccak256(abi.encodePacked(questID2,period2,index2, userB, claimableAmount2));

    bytes32 root = m .getRoot(leafNodes);
    userA_PROOF_2 = m.getProof(leafNodes, 0);
    userB_PROOF_2 = m.getProof(leafNodes, 1);

    assertTrue(m.verifyProof(root, userA_PROOF_2, leafNodes[0]));
    assertTrue(m.verifyProof(root, userB_PROOF_2, leafNodes[1]));

    // Agregar el quest con un token de recompensa (podrías usar la dirección de un MockERC20 aquí)
    vm.prank(mockQuestBoard);
    distributor.addQuest(questID, address(token)); // Asegúrate de que 'token' sea el token de recompensa correcto

    // Agregar el periodo para el quest antes de intentar actualizarlo
    vm.prank(mockQuestBoard);
    distributor.addQuestPeriod(questID, period, claimableAmount);

    // Ahora sí, actualizar el periodo con el Merkle Root
    vm.prank(mockQuestBoard);
    distributor.updateQuestPeriod(questID, period, claimableAmount, root);

    vm.prank(userA);
    distributor.claim(questID, period, index, userA, 0 ether, userA_PROOF_2); // Claim with 0 amount

    // Now, attempt to claim the actual amount
    vm.prank(userA);
    vm.expectRevert("AlreadyClaimed"); // Expecting this revert based on the suspected issue
    distributor.claim(questID, period, index, userA, 500 ether, userA_PROOF_2); // Attempt to claim the correct amount
}


}