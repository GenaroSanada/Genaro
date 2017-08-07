pragma solidity ^0.4.13;

import './GenaroTokenSaleMock.sol';

contract MultisigMock {
  function deployAndSetGNR(address sale) {
    GNR token = new GNR(new MiniMeTokenFactory());
    GRPlaceholder networkPlaceholder = new GRPlaceholder(sale, token);
    token.changeController(address(sale));

    GenaroTokenSale s = GenaroTokenSale(sale);
    token.setCanCreateGrants(sale, true);
    s.setGNR(token, networkPlaceholder, new SaleWallet(s.genaroDevMultisig(), s.finalBlock(), sale));
  }

  function activateSale(address sale) {
    GenaroTokenSale(sale).activateSale();
  }

  function emergencyStopSale(address sale) {
    GenaroTokenSale(sale).emergencyStopSale();
  }

  function restartSale(address sale) {
    GenaroTokenSale(sale).restartSale();
  }

  function finalizeSale(address sale) {
    finalizeSale(sale, GenaroTokenSaleMock(sale).mock_hiddenCap());
  }

  function withdrawWallet(address sale) {
    SaleWallet(GenaroTokenSale(sale).saleWallet()).withdraw();
  }

  function finalizeSale(address sale, uint256 cap) {
    GenaroTokenSale(sale).finalizeSale(cap, GenaroTokenSaleMock(sale).mock_capSecret());
  }

  function deployNetwork(address sale, address network) {
    GenaroTokenSale(sale).deployNetwork(network);
  }

  function () payable {}
}
