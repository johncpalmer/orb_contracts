// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Orb.sol";
import "../src/interfaces/IWorldID.sol";

contract DeployOrb is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory network = vm.envString("NETWORK");

        address worldIdAddress;
        string memory appId;
        string memory actionId;

        if (keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("optimism-sepolia"))) {
            worldIdAddress = vm.envAddress("WORLDCOIN_ADDRESS_OPTIMISM_SEPOLIA");
            appId = vm.envString("WORLDCOIN_APP_ID_SEPOLIA");
            actionId = vm.envString("WORLDCOIN_ACTION_SEPOLIA");
        } else if (keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("worldchain-sepolia"))) {
            worldIdAddress = vm.envAddress("WORLDCOIN_ADDRESS_WORLDCHAIN_SEPOLIA");
            appId = vm.envString("WORLDCOIN_APP_ID_SEPOLIA");
            actionId = vm.envString("WORLDCOIN_ACTION_SEPOLIA");
        } else if (keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("worldchain-mainnet"))) {
            worldIdAddress = vm.envAddress("WORLDCOIN_ADDRESS_WORLDCHAIN_MAINNET");
            appId = vm.envString("WORLDCOIN_APP_ID_MAINNET");
            actionId = vm.envString("WORLDCOIN_ACTION_MAINNET");
        } else {
            revert("Unsupported network");
        }

        vm.startBroadcast(deployerPrivateKey);

        Orb orb = new Orb(
            IWorldID(worldIdAddress),
            appId,
            actionId
        );

        console.log("Orb deployed at:", address(orb));
        console.log("Deployed on network:", network);
        console.log("World ID address:", worldIdAddress);
        console.log("App ID:", appId);
        console.log("Action ID:", actionId);

        vm.stopBroadcast();
    }
}