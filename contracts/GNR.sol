pragma solidity ^0.4.13;

import "./MiniMeIrrevocableVestedToken.sol";

/*
    Copyright 2017, Sanada(Genaro Network)
*/

contract GNR is MiniMeIrrevocableVestedToken {
  // @dev GNR constructor just parametrizes the MiniMeIrrevocableVestedToken constructor
  function GNR(
    address _tokenFactory
  ) MiniMeIrrevocableVestedToken(
    _tokenFactory,
    0x0,                    // no parent token
    0,                      // no snapshot block number from parent
    "Gen Network Token", // Token name
    9,                     // Decimals
    "GER",                  // Symbol
    true                    // Enable transfers
    ) {}
}
