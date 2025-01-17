// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployRaffle is Script {
  function deployContract() public returns (Raffle, HelperConfig) {
    HelperConfig helperConfig = new HelperConfig();
    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

    vm.startBroadcast();
    Raffle raffle = new Raffle(
      config.entranceFee,
      config.interval,
      config.vrfCoordinator,
      config.gasLane,
      config.subscriptionId,
      config.callbackGasLimit
    );
    vm.stopBroadcast();

    return (raffle, helperConfig);
  }

  function run() public {}
}
