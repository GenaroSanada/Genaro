var GenaroTokenSale = artifacts.require("GenaroTokenSale");
var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var GRPlaceholder = artifacts.require("GRPlaceholder");
var GNR = artifacts.require("GNR");
var SaleWallet = artifacts.require("SaleWallet");


module.exports = function(deployer, network, accounts) {
  // if (network.indexOf('dev') > -1) return // dont deploy on tests

//  const genaroMulSig =    '0x46aF1e065eDfdC4E6C2c0c8a4361ae68776Cb375'  //may change later

  // const genaroMulSig = "0xD37333De13DE74eD6F4198364A79DBdB1F438135"
  const mainAccount = accounts[0]
  // const mainAccount = accounts[5]  //testnet 
  const genaroMulSig = mainAccount
  // const initialBlock = 4169220        //  Aug. 17 initialBlock
  // const finalBlock =   4222572        //  finalBlock

  console.log('accounts: ',mainAccount);
  //ropsten test
  const initialBlock = 1480850
  const finalBlock =   1562598

  deployer.deploy(MiniMeTokenFactory);
  deployer.deploy(GenaroTokenSale, initialBlock, finalBlock, genaroMulSig, 14000 , '0x9f1c7e5452f0a10a2e2cde94d82e8d9e3204c4d012b7396127fc304d6dcac414')
    .then(() => {
      return MiniMeTokenFactory.deployed()
        .then(f => {
          factory = f
          return GenaroTokenSale.deployed()
        })
        .then(s => {
          sale = s
          return GNR.new(factory.address)
        }).then(x => {
          GNR = x
          console.log('GNR:', GNR.address)
          return GNR.changeController(sale.address)
        })
        .then(() => {
          return GNR.setCanCreateGrants(sale.address, true)
        })
        .then(() => {
          return GNR.changeVestingWhitelister(genaroMulSig)
        })
        .then(() => {
          return GRPlaceholder.new(sale.address, GNR.address)
        })
        .then(n => {
          networkPlaceholder = n
          console.log('Placeholder:', networkPlaceholder.address)
          return SaleWallet.new(genaroMulSig, finalBlock, sale.address)
        })
        .then(wallet => {
          console.log('Wallet:', wallet.address)
          if (genaroMulSig != mainAccount) {
            console.log(sale.setGNR.request(GNR.address, networkPlaceholder.address, wallet.address))
          } else {
            console.log('Test mode, setting GNR')
            return sale.setGNR(GNR.address, networkPlaceholder.address, wallet.address)
          }
        })
        .then(() => {
          if (genaroMulSig != mainAccount) return
          sale.activateSale()
        })
    })
};
