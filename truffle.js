require('babel-register');
require('babel-polyfill');

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", 
      gas: 4700000,
      gasPrice: 5000000000,          
    },
     test: {
      host: "localhost",
      port: 8545,
      network_id: "*", 
      gas: 10000000000,
      gasPrice: 10000000,     
   }       
  }
};

