require('babel-register');
require('babel-polyfill');

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 4700000,
      gasPrice: 10000000000,
      //from:'0x9169893264234319a5380b01d7a409138127fd5f'
      // from:'0x1b60c53dea7c13285f80013e44539fa43b9f1be5'  //geth
      // from:'0x00Bb97921B83DC5408105269558DE38c911307fb'
      // from:'0x00Bb97921B83DC5408105269558DE38c911307fb' //mainnet
      // from:'0x00Bb1A50b1f40f068d19A71a6742A6910a64585f'  //kovan --whitelist
      // from:'0x00135290b8E84af3262cE22100e90b4F466A9e9C'  //kovan --restored
      // from:'0x00cf7E1198Cb27e6a28abd97E8890ACE000275aa' //ropsten
      // from:'0x00d3c6F11Be59B84D30db590941B81323AAB5a00'   //ropsten 
      //from:'0x00Bb97921B83DC5408105269558DE38c911307fb'
    },
     test: {
     provider: require('ethereumjs-testrpc').provider({ gasLimit: 100000000 }),
     network_id: "*"
   }    
  }
};

