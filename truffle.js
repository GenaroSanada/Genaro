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
    },
     test: {
     provider: require('ethereumjs-testrpc').provider({ gasLimit: 100000000 }),
     network_id: "*"
   }    
  }
};

