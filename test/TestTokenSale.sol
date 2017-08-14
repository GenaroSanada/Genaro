pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "zeppelin/token/ERC20.sol";
import "./helpers/GenaroTokenSaleMock.sol";
import "./helpers/ThrowProxy.sol";
import "./helpers/MultisigMock.sol";
import "./helpers/NetworkMock.sol";

contract TestTokenSale {
  uint public initialBalance = 200 finney;

  address factory;

  ThrowProxy throwProxy;


  function beforeAll() {
    factory = address(new MiniMeTokenFactory());
  }

  function beforeEach() {
    throwProxy = new ThrowProxy(address(this));
  }

function testAllocatesTokensInSale() {
    MultisigMock ms = new MultisigMock();

    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetGNR(sale);
    ms.activateSale(sale);
    sale.setMockedBlockNumber(12);
    //Assert.isTrue(sale.proxyPayment.value(25 finney)(address(this)), 'proxy payment should succeed'); // Gets 5 @ 10 finney
    //Assert.equal(sale.totalCollected(), 25 finney, 'Should have correct total collected');

    sale.setMockedBlockNumber(17);
    //if (!sale.proxyPayment.value(10 finney)(address(this))) throw; // Gets 1 @ 20 finney

    //Assert.equal(ERC20(sale.token()).balanceOf(address(this)), 105 finney, 'Should have correct balance after allocation');
    //Assert.equal(ERC20(sale.token()).totalSupply(), 105 finney, 'Should have correct supply after allocation');
    //Assert.equal(sale.saleWallet().balance, 35 finney, 'Should have sent money to multisig');
    //Assert.equal(sale.totalCollected(), 35 finney, 'Should have correct total collected');
  }

  function testCannotGetTokensInNotInitiatedSale() {
    TestTokenSale(throwProxy).throwsWhenGettingTokensInNotInitiatedSale();
    throwProxy.assertThrows("Should have thrown when sale is not activated");
  }

  function throwsWhenGettingTokensInNotInitiatedSale() {
    MultisigMock ms = new MultisigMock();

    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(ms), address(this), 3, 1, 2);
    ms.deployAndSetGNR(sale);
    ms.activateSale(sale);
    // Would need activation from this too

    //sale.setMockedBlockNumber(12);
    sale.setMockedBlockNumber(9);  
    sale.proxyPayment.value(50 finney)(address(this));
  }

  function testEmergencyStop() {
    MultisigMock ms = new MultisigMock();
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetGNR(sale);
    ms.activateSale(sale);

    sale.setMockedBlockNumber(12);
    Assert.isTrue(sale.proxyPayment.value(15 finney)(address(this)), 'proxy payment should succeed');
    Assert.equal(ERC20(sale.token()).balanceOf(address(this)), 45 finney, 'Should have correct balance after allocation');

    ms.emergencyStopSale(address(sale));
    Assert.isTrue(sale.saleStopped(), "Sale should be stopped");

    ms.restartSale(sale);

    sale.setMockedBlockNumber(16);
    Assert.isFalse(sale.saleStopped(), "Sale should be restarted");
    Assert.isTrue(sale.proxyPayment.value(1 finney)(address(this)), 'proxy payment should succeed');
    Assert.equal(ERC20(sale.token()).balanceOf(address(this)), 48 finney, 'Should have correct balance after allocation');
  }

  function testCantBuyTokensInStoppedSale() {
    TestTokenSale(throwProxy).throwsWhenGettingTokensWithStoppedSale();
    throwProxy.assertThrows("Should have thrown when sale is stopped");
  }

  function throwsWhenGettingTokensWithStoppedSale() {
    MultisigMock ms = new MultisigMock();
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetGNR(sale);
    ms.activateSale(sale);
    sale.setMockedBlockNumber(12);

    ms.emergencyStopSale(address(sale));
    sale.proxyPayment.value(20 finney)(address(this));
  }

  function testCantBuyTokensInEndedSale() {
    TestTokenSale(throwProxy).throwsWhenGettingTokensWithEndedSale();
    throwProxy.assertThrows("Should have thrown when sale is ended");
  }

  function throwsWhenGettingTokensWithEndedSale() {
    MultisigMock ms = new MultisigMock();
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetGNR(sale);
    ms.activateSale(sale);
    sale.setMockedBlockNumber(21);

    sale.proxyPayment.value(20 finney)(address(this));
  }

  function testTokensAreLockedDuringSale() {
    TestTokenSale(throwProxy).throwsWhenTransferingDuringSale();
    throwProxy.assertThrows("Should have thrown transferring during sale");
  }

  function throwsWhenTransferingDuringSale() {
    MultisigMock ms = new MultisigMock();
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetGNR(sale);
    ms.activateSale(sale);
    sale.setMockedBlockNumber(12);
    sale.proxyPayment.value(15 finney)(address(this));

    ERC20(sale.token()).transfer(0x1, 10 finney);
  }

  function testTokensAreTransferrableAfterSale() {
    MultisigMock ms = new MultisigMock();
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetGNR(sale);
    ms.activateSale(sale);

    Assert.equal(GNR(sale.token()).controller(), address(sale), "Sale is controller during sale");

    sale.setMockedBlockNumber(12);
    sale.proxyPayment.value(15 finney)(address(this));
    sale.setMockedBlockNumber(22);
    ms.finalizeSale(sale);

    Assert.equal(GNR(sale.token()).controller(), sale.networkPlaceholder(), "Network placeholder is controller after sale");

    ERC20(sale.token()).transfer(0x1, 10 finney);
    Assert.equal(ERC20(sale.token()).balanceOf(0x1), 10 finney, 'Should have correct balance after receiving tokens');
  }

  function testFundsAreTransferrableAfterSale() {
    MultisigMock ms = new MultisigMock();
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetGNR(sale);
    ms.activateSale(sale);

    Assert.equal(GNR(sale.token()).controller(), address(sale), "Sale is controller during sale");

    sale.setMockedBlockNumber(12);
    sale.proxyPayment.value(15 finney)(address(this));
    sale.setMockedBlockNumber(22);
    ms.finalizeSale(sale);

    ms.withdrawWallet(sale);
    Assert.equal(ms.balance, 15 finney, "Funds are collected after sale");
  }

//  function testFundsAreLockedDuringSale() {
//    TestTokenSale(throwProxy).throwsWhenTransferingFundsDuringSale();
//    throwProxy.assertThrows("Should have thrown transferring funds during sale");
//  }

  function testWhenTransferingFundsDuringSale() {
    MultisigMock ms = new MultisigMock();
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetGNR(sale);
    ms.activateSale(sale);

    Assert.equal(GNR(sale.token()).controller(), address(sale), "Sale is controller during sale");

    sale.setMockedBlockNumber(12);
    sale.proxyPayment.value(15 finney)(address(this));
    sale.setMockedBlockNumber(22);
    ms.finalizeSale(sale);

    ms.withdrawWallet(sale);
    Assert.equal(ms.balance, 15 finney, "Funds are collected after sale");
  }

  function testNetworkDeployment() {
    MultisigMock devMultisig = new MultisigMock();
    MultisigMock ms = new MultisigMock();

    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(devMultisig), address(ms), 3, 1, 2);
    devMultisig.deployAndSetGNR(sale);
    devMultisig.activateSale(sale);

    Assert.equal(GNR(sale.token()).controller(), address(sale), "Sale is controller during sale");
    sale.setMockedBlockNumber(12);
    sale.proxyPayment.value(15 finney)(address(this));
    sale.setMockedBlockNumber(22);
    devMultisig.finalizeSale(sale);

    Assert.equal(GNR(sale.token()).controller(), sale.networkPlaceholder(), "Network placeholder is controller after sale");

    doTransfer(sale.token());
  }

  function doTransfer(address token) {
    GNR(token).transfer(0x1, 10 finney);
  }
}
