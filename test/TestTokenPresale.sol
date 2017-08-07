pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "zeppelin/token/ERC20.sol";
import "./helpers/GenaroTokenSaleMock.sol";
import "./helpers/ThrowProxy.sol";
import "./helpers/MultisigMock.sol";

contract TestTokenPresale {
  uint public initialBalance = 200 finney;

  GNR token;

  ThrowProxy throwProxy;

  function beforeEach() {
    throwProxy = new ThrowProxy(address(this));
  }

  function deployAndSetGNR(GenaroTokenSale sale) {
    GNR a = new GNR(new MiniMeTokenFactory());
    a.changeController(sale);
    a.setCanCreateGrants(sale, true);
    sale.setGNR(a, new GRPlaceholder(address(sale), a), new SaleWallet(sale.genaroDevMultisig(), sale.finalBlock(), address(sale)));
  }

  function testCreateSale() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, 0x1, 0x2, 3, 1, 2);

    Assert.isFalse(sale.isActivated(), "Sale should be activated");
    Assert.equal(sale.totalCollected(), 0, "Should start with 0 funds collected");
  }

  function testCantInitiateIncorrectSale() {
    TestTokenPresale(throwProxy).throwIfStartPastBlocktime();
    throwProxy.assertThrows("Should throw when starting a sale in a past block");
  }

  function throwIfStartPastBlocktime() {
    new GenaroTokenSaleMock(0, 20, 0x1, 0x2, 3, 1, 2);
  }

  function testActivateSale() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetGNR(sale);
    sale.activateSale();
    Assert.isTrue(sale.isActivated(), "Should be activated");
  }

  function testCannotActivateBeforeDeployingGNR() {
    TestTokenPresale(throwProxy).throwsWhenActivatingBeforeDeployingGNR();
    throwProxy.assertThrows("Should have thrown when activating before deploying GNR");
  }

  function throwsWhenActivatingBeforeDeployingGNR() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    sale.activateSale();
  }

  function testCannotRedeployGNR() {
    TestTokenPresale(throwProxy).throwsWhenRedeployingGNR();
    throwProxy.assertThrows("Should have thrown when redeploying GNR");
  }

  function throwsWhenRedeployingGNR() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetGNR(sale);
    deployAndSetGNR(sale);
  }

  function testOnlyMultisigCanDeployGNR() {
    TestTokenPresale(throwProxy).throwsWhenNonMultisigDeploysGNR();
    throwProxy.assertThrows("Should have thrown when deploying GNR from not multisig");
  }

  function throwsWhenNonMultisigDeploysGNR() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, 0x1, 0x3, 3, 1, 2);
    deployAndSetGNR(sale);
  }

  function testThrowsIfPlaceholderIsBad() {
    TestTokenPresale(throwProxy).throwsWhenNetworkPlaceholderIsBad();
    throwProxy.assertThrows("Should have thrown when placeholder is not correct");
  }

  function throwsWhenNetworkPlaceholderIsBad() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    GNR a = new GNR(new MiniMeTokenFactory());
    a.changeController(sale);
    sale.setGNR(a, new GRPlaceholder(address(sale), address(sale)), new SaleWallet(sale.genaroDevMultisig(), sale.finalBlock(), address(sale))); // should be initialized with token address
  }

  function testThrowsIfSaleIsNotTokenController() {
    TestTokenPresale(throwProxy).throwsWhenSaleIsNotTokenController();
    throwProxy.assertThrows("Should have thrown when sale is not token controller");
  }

  function throwsWhenSaleIsNotTokenController() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    GNR a = new GNR(new MiniMeTokenFactory());
    // Not called a.changeController(sale);
    sale.setGNR(a, new GRPlaceholder(address(sale), a), new SaleWallet(sale.genaroDevMultisig(), sale.finalBlock(), address(sale))); // should be initialized with token address
  }

  function testThrowsSaleWalletIncorrectBlock() {
    TestTokenPresale(throwProxy).throwsSaleWalletIncorrectBlock();
    throwProxy.assertThrows("Should have thrown sale wallet releases in incorrect block");
  }

  function throwsSaleWalletIncorrectBlock() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    GNR a = new GNR(new MiniMeTokenFactory());
    a.changeController(sale);
    sale.setGNR(a, new GRPlaceholder(address(sale), a), new SaleWallet(sale.genaroDevMultisig(), sale.finalBlock() - 1, address(sale)));
  }

  function testThrowsSaleWalletIncorrectMultisig() {
    TestTokenPresale(throwProxy).throwsSaleWalletIncorrectMultisig();
    throwProxy.assertThrows("Should have thrown when sale wallet has incorrect multisig");
  }

  function throwsSaleWalletIncorrectMultisig() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    GNR a = new GNR(new MiniMeTokenFactory());
    a.changeController(sale);
    sale.setGNR(a, new GRPlaceholder(address(sale), a), new SaleWallet(0x1a77ed, sale.finalBlock(), address(sale)));
  }

  function testThrowsSaleWalletIncorrectSaleAddress() {
    TestTokenPresale(throwProxy).throwsSaleWalletIncorrectSaleAddress();
    throwProxy.assertThrows("Should have thrown when sale wallet has incorrect sale address");
  }

  function throwsSaleWalletIncorrectSaleAddress() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    GNR a = new GNR(new MiniMeTokenFactory());
    a.changeController(sale);
    sale.setGNR(a, new GRPlaceholder(address(sale), a), new SaleWallet(sale.genaroDevMultisig(), sale.finalBlock(), 0xdead));
  }

  function testSetPresaleTokens() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), 0x2, 3, 1, 2);
    deployAndSetGNR(sale);
    sale.allocatePresaleTokens(0x1, 100 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    sale.allocatePresaleTokens(0x2, 30 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    sale.allocatePresaleTokens(0x2, 6 finney, uint64(now + 8 weeks), uint64(now + 24 weeks));
    sale.allocatePresaleTokens(address(this), 20 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    Assert.equal(ERC20(sale.token()).balanceOf(0x1), 100 finney, 'Should have correct balance after allocation');
    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now)), 0, 'Should have 0 tokens transferable now');
    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 12 weeks - 1)), 0, 'Should have 0 tokens transferable just before cliff');
    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 12 weeks)), 50 finney, 'Should have some tokens transferable after cliff');
    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 18 weeks)), 75 finney, 'Should have some tokens transferable during vesting');
    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 21 weeks)), 87500 szabo, 'Should have some tokens transferable during vesting');
    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 24 weeks)), 100 finney, 'Should have all tokens transferable after vesting');

    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x2, uint64(now)), 0, 'Should have all tokens transferable after vesting');
    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x2, uint64(now + 8 weeks)), 2 finney, 'Should have all tokens transferable after vesting');
    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x2, uint64(now + 12 weeks)), 18 finney, 'Should have all tokens transferable after vesting');
    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x2, uint64(now + 24 weeks)), 36 finney, 'Should have all tokens transferable after vesting');
    Assert.equal(MiniMeIrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 24 weeks)), 100 finney, 'Should have all tokens transferable after vesting');

    Assert.equal(ERC20(sale.token()).totalSupply(), 156 finney, 'Should have correct supply after allocation');

    Assert.equal(ERC20(sale.token()).balanceOf(this), 20 finney, 'Should have correct balance');
    TestTokenPresale(throwProxy).throwsWhenTransferingPresaleTokensBeforeCliff(sale.token());
    throwProxy.assertThrows("Should have thrown when transfering presale tokens");
  }

  function throwsWhenTransferingPresaleTokensBeforeCliff(address token) {
    ERC20(token).transfer(0xdead, 1);
  }

  function testCannotSetPresaleTokensAfterActivation() {
    TestTokenPresale(throwProxy).throwIfSetPresaleTokensAfterActivation();
    throwProxy.assertThrows("Should have thrown when setting tokens after activation");
  }

  function throwIfSetPresaleTokensAfterActivation() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetGNR(sale);
    sale.activateSale(); // this is both multisigs
    sale.allocatePresaleTokens(0x1, 100, uint64(now + 12 weeks), uint64(now + 24 weeks));
  }

  function testCannotSetPresaleTokensAfterSaleStarts() {
    TestTokenPresale(throwProxy).throwIfSetPresaleTokensAfterSaleStarts();
    throwProxy.assertThrows("Should have thrown when setting tokens after sale started");
  }

  function throwIfSetPresaleTokensAfterSaleStarts() {
    GenaroTokenSaleMock sale = new GenaroTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetGNR(sale);
    sale.setMockedBlockNumber(13);
    sale.allocatePresaleTokens(0x1, 100, uint64(now + 12 weeks), uint64(now + 24 weeks));
  }
}
