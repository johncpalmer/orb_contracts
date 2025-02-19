// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ByteHasher } from './helpers/ByteHasher.sol';
import { IWorldID } from './interfaces/IWorldID.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Orb is ERC20, Ownable {
    using ByteHasher for bytes;

    error DuplicateNullifier(uint256 nullifierHash);
    error AlreadyMinted();
    error InvalidProof();

    IWorldID internal immutable worldId;
    uint256 internal immutable externalNullifier;
    uint256 internal immutable groupId = 1;
    mapping(uint256 => bool) internal nullifierHashes;
    mapping(address => bool) public hasMinted;

    uint256 public constant MINT_AMOUNT = 1000 ether;
    uint256 public lastOwnerClaimSupply;

    event Minted(address indexed to, uint256 amount);
    event OwnerTokensClaimed(address indexed owner, uint256 amount);
    event LogMintAttempt(address sender, uint256 root, uint256 nullifierHash);
    event LogMintError(address sender, string errorType, string reason);

    constructor(IWorldID _worldId, string memory _appId, string memory _actionId) ERC20("Orb", "ORB") Ownable(msg.sender) {
        worldId = _worldId;
        externalNullifier = abi.encodePacked(abi.encodePacked(_appId).hashToField(), _actionId).hashToField();
        lastOwnerClaimSupply = 0;
    }

    function mint(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        require(signal != address(0), "Invalid signal address");
        require(root != 0, "Invalid root");
        require(nullifierHash != 0, "Invalid nullifier hash");
        require(proof.length == 8, "Invalid proof length");
        if (hasMinted[msg.sender]) revert AlreadyMinted();
        if (nullifierHashes[nullifierHash]) revert DuplicateNullifier(nullifierHash);

        emit LogMintAttempt(msg.sender, root, nullifierHash);

        try worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            externalNullifier,
            proof
        ) {
            require(signal == msg.sender, "Signal does not match sender");
            nullifierHashes[nullifierHash] = true;
            hasMinted[msg.sender] = true;

            _mint(msg.sender, MINT_AMOUNT);

            emit Minted(msg.sender, MINT_AMOUNT);
        } catch Error(string memory reason) {
            emit LogMintError(msg.sender, "Error", reason);
            revert("WorldID verification failed");
        } catch (bytes memory lowLevelData) {
            emit LogMintError(msg.sender, "LowLevelError", _toHexString(lowLevelData));
            revert("WorldID verification failed");
        }
    }

    function claimOwnerTokens() public onlyOwner {
        uint256 currentSupply = totalSupply();
        uint256 claimAmount;

        if (lastOwnerClaimSupply == 0) {
            // First claim: 1% of current total supply
            claimAmount = currentSupply / 100;
        } else {
            // Subsequent claims: 1% of new supply since last claim
            uint256 newSupply = currentSupply - lastOwnerClaimSupply;
            claimAmount = newSupply / 100;
        }

        lastOwnerClaimSupply = currentSupply + claimAmount;
        _mint(owner(), claimAmount);

        emit OwnerTokensClaimed(owner(), claimAmount);
    }

    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    function _toHexString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        _transferOwnership(newOwner);
    }
}