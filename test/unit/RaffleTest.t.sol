// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

contract RaffleTest is Test {
  Raffle public raffle;
  HelperConfig public helperConfig;

  uint256 entranceFee;
  uint256 interval;
  address vrfCoordinator;
  bytes32 gasLane;
  uint256 subscriptionId;
  uint32 callbackGasLimit;

  address public PLAYER = makeAddr("player");
  uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

  function setUp() external {
    DeployRaffle deployer = new DeployRaffle();
    (raffle, helperConfig) = deployer.deployContract();

    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
    entranceFee = config.entranceFee;
    interval = config.interval;
    vrfCoordinator = config.vrfCoordinator;
    gasLane = config.gasLane;
    subscriptionId = config.subscriptionId;
    callbackGasLimit = config.callbackGasLimit;
  }

  function testRaffleInitializedInOpenState() public view {
    assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
  }
}
