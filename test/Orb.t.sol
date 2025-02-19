// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Orb.sol";
import "./mocks/WorldIDMock.sol";

contract OrbTest is Test {
    Orb public orb;
    WorldIDMock public worldIdMock;
    address public constant ALICE = address(0x1);
    address public constant BOB = address(0x2);
    address public constant OWNER = address(0x3);
    uint256 public constant MINT_AMOUNT = 1000 ether;

    event Minted(address indexed to, uint256 amount);
    event OwnerTokensClaimed(address indexed owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        worldIdMock = new WorldIDMock();
        vm.prank(OWNER);
        orb = new Orb(IWorldID(address(worldIdMock)), "app_id", "action_id");
    }

    function testMintSuccess() public {
        uint256 root = 1;
        uint256 nullifierHash = 2;
        uint256[8] memory proof = [uint256(3), 0, 0, 0, 0, 0, 0, 0];

        vm.prank(ALICE);
        orb.mint(ALICE, root, nullifierHash, proof);

        assertEq(orb.balanceOf(ALICE), MINT_AMOUNT);
    }

    function testCannotMintTwice() public {
        uint256 root = 1;
        uint256 nullifierHash = 2;
        uint256[8] memory proof = [uint256(3), 0, 0, 0, 0, 0, 0, 0];

        vm.startPrank(ALICE);
        orb.mint(ALICE, root, nullifierHash, proof);
        
        vm.expectRevert(Orb.AlreadyMinted.selector);
        orb.mint(ALICE, root, nullifierHash, proof);
        vm.stopPrank();
    }

    function testClaimOwnerTokensFirstTime() public {
        // Mint some tokens to create initial supply
        uint256 root = 1;
        uint256 nullifierHash = 2;
        uint256[8] memory proof = [uint256(3), 0, 0, 0, 0, 0, 0, 0];

        vm.prank(ALICE);
        orb.mint(ALICE, root, nullifierHash, proof);

        uint256 initialSupply = orb.totalSupply();
        uint256 expectedClaim = (initialSupply * 10) / 1000; // 1% of initial supply

        vm.prank(OWNER);
        vm.expectEmit(true, true, false, true);
        emit OwnerTokensClaimed(OWNER, expectedClaim);
        orb.claimOwnerTokens();

        assertEq(orb.balanceOf(OWNER), expectedClaim);
        assertEq(orb.totalSupply(), initialSupply + expectedClaim);
    }

    function testClaimOwnerTokensSubsequentClaim() public {
        // First claim
        testClaimOwnerTokensFirstTime();

        uint256 supplyAfterFirstClaim = orb.totalSupply();
        uint256 firstClaimAmount = orb.balanceOf(OWNER);
        
        // Mint more tokens
        uint256 root = 1;
        uint256 nullifierHash = 3;
        uint256[8] memory proof = [uint256(4), 0, 0, 0, 0, 0, 0, 0];

        vm.prank(BOB);
        orb.mint(BOB, root, nullifierHash, proof);

        uint256 newSupply = orb.totalSupply() - supplyAfterFirstClaim;
        uint256 expectedSecondClaim = (newSupply * 10) / 1000; // 1% of new supply

        vm.prank(OWNER);
        vm.expectEmit(true, true, false, true);
        emit OwnerTokensClaimed(OWNER, expectedSecondClaim);
        orb.claimOwnerTokens();

        uint256 expectedTotalOwnerBalance = firstClaimAmount + expectedSecondClaim;
        assertEq(orb.balanceOf(OWNER), expectedTotalOwnerBalance, "Owner balance mismatch");
        assertEq(orb.totalSupply(), supplyAfterFirstClaim + MINT_AMOUNT + expectedSecondClaim, "Total supply mismatch");

        // Add these lines for debugging
        console.log("First claim amount:", firstClaimAmount);
        console.log("Second claim amount:", expectedSecondClaim);
        console.log("Expected total owner balance:", expectedTotalOwnerBalance);
        console.log("Actual owner balance:", orb.balanceOf(OWNER));
        console.log("Total supply:", orb.totalSupply());
    }

    function testOnlyOwnerCanClaimTokens() public {
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", ALICE));
        orb.claimOwnerTokens();
    }

    function testRenounceOwnership() public {
        vm.prank(OWNER);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(OWNER, address(0));
        orb.renounceOwnership();

        assertEq(orb.owner(), address(0));
    }

    function testCannotClaimAfterRenouncingOwnership() public {
        vm.prank(OWNER);
        orb.renounceOwnership();

        vm.prank(OWNER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", OWNER));
        orb.claimOwnerTokens();
    }

    function testRenounceOwnershipDoesNotRevert() public {
        // Ensure the owner is set correctly
        assertEq(orb.owner(), OWNER);

        // Renounce ownership
        vm.prank(OWNER);
        orb.renounceOwnership();

        // Check that ownership has been renounced
        assertEq(orb.owner(), address(0));
    }

    function testCannotMintWithInvalidProof() public {
        uint256 root = 1;
        uint256 nullifierHash = 2;
        uint256[8] memory invalidProof = [uint256(999), 0, 0, 0, 0, 0, 0, 0]; // Invalid proof

        // Configure the WorldIDMock to fail verification
        worldIdMock.setVerificationResult(false);

        vm.prank(ALICE);
        vm.expectRevert("WorldID verification failed");
        orb.mint(ALICE, root, nullifierHash, invalidProof);

        // Ensure no tokens were minted
        assertEq(orb.balanceOf(ALICE), 0);
    }

    function testOwnershipTransfer() public {
        address newOwner = address(0x1234);

        // Check initial owner
        assertEq(orb.owner(), OWNER);

        // Transfer ownership
        vm.prank(OWNER);
        orb.transferOwnership(newOwner);

        // Check new owner
        assertEq(orb.owner(), newOwner);

        // Ensure old owner can't call onlyOwner functions anymore
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", OWNER));
        vm.prank(OWNER);
        orb.transferOwnership(OWNER);

        // Ensure new owner can call onlyOwner functions
        vm.prank(newOwner);
        orb.transferOwnership(OWNER);
        assertEq(orb.owner(), OWNER);
    }
}