pragma solidity ^0.4.13;

import '../../contracts/GenaroTokenSale.sol';

// @dev GenaroTokenSaleMock mocks current block number

contract GenaroTokenSaleMock is GenaroTokenSale {

  function GenaroTokenSaleMock (
      uint _initialBlock,
      uint _finalBlock,
      address _genaroDevMultisig,
      address _communityMultisig,
      uint256 _initialPrice,
      uint256 _finalPrice,
      uint8 _priceStages
  ) GenaroTokenSale(_initialBlock, _finalBlock, _genaroDevMultisig, _initialPrice, computeCap(mock_hiddenCap, mock_capSecret)) {

  }

  function getBlockNumber() internal constant returns (uint) {
    return mock_blockNumber;
  }

  function setMockedBlockNumber(uint _b) {
    mock_blockNumber = _b;
  }

  function setMockedTotalCollected(uint _totalCollected) {
    totalCollected = _totalCollected;
  }

  uint mock_blockNumber = 1;

  uint public mock_hiddenCap = 100 finney;
  uint public mock_capSecret = 1;
}
