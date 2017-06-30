pragma solidity ^0.4.13;

import "./interface/Controller.sol";
import "./GNR.sol";

/*

@notice The GRPlaceholder contract will take control over the GNR after the sale
        is finalized and before the Genaro Network is deployed.

        The contract allows for GNR transfers and transferFrom and implements the
        logic for transfering control of the token to the network when the sale
        asks it to do so.
*/

contract GRPlaceholder is Controller {
  address public sale;
  GNR public token;

  function GRPlaceholder(address _sale, address _gnr) {
    sale = _sale;
    token = GNR(_gnr);
  }

  function changeController(address network) public {
    require(msg.sender == sale);
    token.changeController(network);
    suicide(network);
  }

  // In between the sale and the network. Default settings for allowing token transfers.
  function proxyPayment(address) payable public returns (bool) {
    return false;
  }

  function onTransfer(address, address, uint) public returns (bool) {
    return true;
  }

  function onApprove(address, address, uint) public returns (bool) {
    return true;
  }
}