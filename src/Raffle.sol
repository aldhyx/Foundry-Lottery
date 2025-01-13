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

/**
 * @title a sample Raffle contract
 * @author Frialdhy S. Ketty
 * @notice This contract is for creating a sample raffle
 * @dev Implement Chainlink VRFv2.5
 */
contract Raffle {
  /* Errors */
  error Raffle__SendMoreToEnterRaffle();

  /* State variables */
  uint256 private immutable i_entranceFee;
  address payable[] private s_players; // -> list of diff players who entered the raffle

  /* Events */
  event RaffleEntered(address indexed player);

  constructor(uint256 entranceFee) {
    i_entranceFee = entranceFee;
  }

  function enterRaffle() public payable {
    // require(msg.value >= i_entranceFee, "Send more to enter raffle"); -> this costly
    // require(msg.value >= i_entranceFee, Raffle__SendMoreToEnterRaffle()); -> this only works in specific version

    // -> This is more gas efficient
    if (msg.value >= i_entranceFee) {
      revert Raffle__SendMoreToEnterRaffle();
    }

    s_players.push(payable(msg.sender)); // -> update s_players storage
    emit RaffleEntered(msg.sender); // -> anytime you update the storage, you need to emit an event
  }

  function pickWinner() public {}

  //** Getter functions */
  function getEntranceFee() external view returns (uint256) {
    return i_entranceFee;
  }
}
