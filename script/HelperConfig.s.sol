// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
  /* VRF mock values */
  uint96 public constant VRF_BASE_FEE = 0.25 ether;
  uint96 public constant VRF_GAS_PRICE = 1e9;
  int256 public constant VRF_WEI_PER_UNIT_LINK = 4e15; // LINK/ETH Price

  uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
  uint256 public constant ETH_LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
  error HelperConfig__InvalidChainId();

  struct NetworkConfig {
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
  }

  NetworkConfig public localNetworkConfig;
  mapping(uint256 chainId => NetworkConfig) public networkConfigs;

  constructor() {
    networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaConfig();
  }

  function getConfigByChainId(
    uint256 chainId
  ) public returns (NetworkConfig memory) {
    if (networkConfigs[chainId].vrfCoordinator != address(0)) {
      return networkConfigs[chainId];
    } else if (chainId == ETH_LOCAL_CHAIN_ID) {
      return getOrCreateAnvilEthConfig();
    } else {
      revert HelperConfig__InvalidChainId();
    }
  }

  function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    // check to see if we have already set the local network config
    if (localNetworkConfig.vrfCoordinator != address(0)) {
      return localNetworkConfig;
    }

    // Deploy mocks
    vm.startBroadcast();
    VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
      VRF_BASE_FEE,
      VRF_GAS_PRICE,
      VRF_WEI_PER_UNIT_LINK
    );
    vm.stopBroadcast();

    localNetworkConfig = NetworkConfig({
      entranceFee: 0.0001 ether,
      interval: 30, // 30 seconds
      vrfCoordinator: address(vrfCoordinatorMock),
      gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
      callbackGasLimit: 500000,
      subscriptionId: 0 // might have to fix this
    });

    return localNetworkConfig;
  }

  function getSepoliaConfig() public pure returns (NetworkConfig memory) {
    return
      NetworkConfig({
        entranceFee: 0.0001 ether,
        interval: 30, // 30 seconds
        vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        callbackGasLimit: 500000,
        subscriptionId: 0
      });
  }
}
