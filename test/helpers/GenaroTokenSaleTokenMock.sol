pragma solidity ^0.4.13;

import './GenaroTokenSaleMock.sol';

// @dev GenaroTokenSaleTokenMock for ERC20 tests purpose.
// As it also deploys MiniMeTokenFactory, nonce will increase and therefore will be broken for future deployments

contract GenaroTokenSaleTokenMock is GenaroTokenSaleMock {

  function GenaroTokenSaleTokenMock(address initialAccount, uint initialBalance)
          GenaroTokenSaleMock(10, 20, msg.sender, msg.sender, 100, 50, 2)
    {
      GNR token = new GNR(new MiniMeTokenFactory());
      GRPlaceholder networkPlaceholder = new GRPlaceholder(this, token);
      token.changeController(address(this));

      setGNR(token, networkPlaceholder, new SaleWallet(msg.sender, 20, address(this)));
      allocatePresaleTokens(initialAccount, initialBalance, uint64(now), uint64(now));
      activateSale();
      setMockedBlockNumber(21);
      finalizeSale(mock_hiddenCap, mock_capSecret);

      token.changeVestingWhitelister(msg.sender);
  }
}
