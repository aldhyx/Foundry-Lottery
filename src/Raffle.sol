/*
 ** Layout of Contract:
 * version
 * imports
 * errors
 * interfaces, libraries, contracts
 * Type declarations
 * State variables
 * Events
 * Modifiers
 * Functions
 *
 ** Layout of Functions:
 * constructor
 * receive function (if exists)
 * fallback function (if exists)
 * external
 * public
 * internal
 * private
 * internal & private view & pure functions
 * external & public view & pure functions
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title a sample Raffle contract
 * @author Frialdhy S. Ketty
 * @notice This contract is for creating a sample raffle
 * @dev Implement Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
  /* Errors */
  error Raffle__SendMoreToEnterRaffle();
  error Raffle__TransferFailed();
  error Raffle__RaffleNotOpen();
  error Raffle__UpKeepNotNeeded(
    uint256 balance,
    uint256 playersLength,
    uint256 raffleState
  );

  /* Type declaration */
  enum RaffleState {
    OPEN,
    CALCULATING_WINNER
  }

  /* State variables */
  uint256 private immutable i_entranceFee;
  // @dev - The duration of the lottery in seconds
  uint256 private immutable i_interval;
  address payable[] private s_players; // -> list of diff players who entered the raffle
  uint256 private s_lastTimestamp;
  address private s_recentWinner;
  RaffleState private s_raffleState;

  /* Chainlink vrf states */
  bytes32 private immutable i_keyHash;
  uint256 private immutable i_subscriptionId;
  uint32 private immutable i_callbackGasLimit;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private constant NUM_WORDS = 1;

  /* Events */
  event RaffleEntered(address indexed player);
  event WinnerPicked(address indexed player);

  constructor(
    uint256 entranceFee,
    uint256 interval,
    address vrfCoordinator,
    bytes32 gasLane,
    uint256 subscriptionId,
    uint32 callbackGasLimit
  ) VRFConsumerBaseV2Plus(vrfCoordinator) {
    i_entranceFee = entranceFee;
    i_interval = interval;
    s_lastTimestamp = block.timestamp;
    i_keyHash = gasLane;
    i_subscriptionId = subscriptionId;
    i_callbackGasLimit = callbackGasLimit;
    s_raffleState = RaffleState.OPEN;
  }

  function enterRaffle() external payable {
    // require(msg.value < i_entranceFee, "Send more to enter raffle"); -> this costly
    // require(msg.value < i_entranceFee, Raffle__SendMoreToEnterRaffle()); -> this only works in specific version

    // More gas efficient
    if (msg.value < i_entranceFee) {
      revert Raffle__SendMoreToEnterRaffle();
    }

    if (s_raffleState != RaffleState.OPEN) {
      revert Raffle__RaffleNotOpen();
    }

    s_players.push(payable(msg.sender)); // update s_players storage
    // Anytime you update the storage, you need to emit an event
    // This will makes migration easier, front-end, indexing easier
    emit RaffleEntered(msg.sender);
  }

  /**
   * @dev This is the function that the Chainlink nodes will call to see if the lottery is ready to have a winner picked.
   * The following should be true in order for upkeepNeeded to be true:
   * 1. The time interval has passed between raffle runs
   * 2. The lottery is open
   * 3. The contract has ETH
   * 4. Implicitly, your subscription has LINK
   * @param - ignored
   * @return upkeepNeeded - true if its time to start the lottery
   * @return - ignored
   */
  function checkUpKeep(
    bytes memory /* checkData */
  ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
    bool timeHasPassed = ((block.timestamp - s_lastTimestamp) >= i_interval);
    bool isOpen = s_raffleState == RaffleState.OPEN;
    bool hasBalance = address(this).balance > 0;
    bool hasPlayers = s_players.length > 0;
    upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
    return (upkeepNeeded, hex"");
  }

  function performUpkeep(bytes calldata /* performData */) external {
    // check to see if enough time has passed

    (bool upkeepNeeded, ) = checkUpKeep("");
    if (!upkeepNeeded) {
      revert Raffle__UpKeepNotNeeded(
        address(this).balance,
        s_players.length,
        uint256(s_raffleState)
      );
    }

    s_raffleState = RaffleState.CALCULATING_WINNER;

    VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
      .RandomWordsRequest({
        keyHash: i_keyHash,
        subId: i_subscriptionId,
        requestConfirmations: REQUEST_CONFIRMATIONS,
        callbackGasLimit: i_callbackGasLimit,
        numWords: NUM_WORDS,
        // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
        extraArgs: VRFV2PlusClient._argsToBytes(
          VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
        )
      });

    uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
  }

  function fulfillRandomWords(
    uint256 requestId,
    uint256[] calldata randomWords
  ) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;

    s_recentWinner = s_players[indexOfWinner];
    s_raffleState = RaffleState.OPEN;
    s_players = new address payable[](0);
    s_lastTimestamp = block.timestamp;
    emit WinnerPicked(s_recentWinner);

    (bool success, ) = s_recentWinner.call{value: address(this).balance}("");
    if (!success) {
      revert Raffle__TransferFailed();
    }
  }

  //** Getter functions */
  function getEntranceFee() external view returns (uint256) {
    return i_entranceFee;
  }

  function getRaffleState() external view returns (RaffleState) {
    return s_raffleState;
  }

  function getPlayer(uint256 indexOfPlayer) external view returns (address) {
    return s_players[indexOfPlayer];
  }
}
