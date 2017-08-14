pragma solidity ^0.4.13;

import "zeppelin/SafeMath.sol";
import "./interface/Controller.sol";
import "./GNR.sol";
import "./GRPlaceholder.sol";
import "./SaleWallet.sol";

contract GenaroTokenSale is Controlled, Controller, SafeMath {
    uint public initialBlock;             // Block number in which the sale starts. Inclusive. sale will be opened at initial block.
    uint public finalBlock;               // Block number in which the sale end. Exclusive, sale will be closed at ends block.
    uint public price;                    // Number of wei-GNR tokens for 1 wei, at the start of the sale (9 decimals) 

    address public genaroDevMultisig;     // The address to hold the funds donated
    bytes32 public capCommitment;

    uint public totalCollected = 0;               // In wei
    bool public saleStopped = false;              // Has Genaro Dev stopped the sale?
    bool public saleFinalized = false;            // Has Genaro Dev finalized the sale?

    mapping (address => bool) public activated;   // Address confirmates that wants to activate the sale

    mapping (address => bool) public whitelist;   // Address consists of whitelist payer

    GNR public token;                             // The token
    GRPlaceholder public networkPlaceholder;      // The network placeholder
    SaleWallet public saleWallet;                 // Wallet that receives all sale funds

    uint constant public dust = 1 finney;         // Minimum investment
    uint constant public maxPerPersion = 100 ether;   // Maximum investment per person

    uint constant public tokenPrice = 7680;    // Genaro token price

    uint public hardCap = 14700 ether;          // Hard cap for Genaro 

    event NewPresaleAllocation(address indexed holder, uint256 gnrAmount);
    event NewBuyer(address indexed holder, uint256 gnrAmount, uint256 etherAmount);
    event CapRevealed(uint value, uint secret, address revealer);

/// @dev There are several checks to make sure the parameters are acceptable
/// @param _initialBlock The Block number in which the sale starts
/// @param _finalBlock The Block number in which the sale ends
/// @param _genaroDevMultisig The address that will store the donated funds and manager
/// for the sale
/// @param _price The price for the genaro sale. Price in wei-GNR per wei.

  function GenaroTokenSale (
      uint _initialBlock,
      uint _finalBlock,
      address _genaroDevMultisig,
      uint256 _price,
      bytes32 _capCommitment
  )
  {
      require(_genaroDevMultisig !=0);
      require(_initialBlock >= getBlockNumber());
      require(_initialBlock < _finalBlock);

      require(uint(_capCommitment)!=0);
      

      // Save constructor arguments as global variables
      initialBlock = _initialBlock;
      finalBlock = _finalBlock;
      genaroDevMultisig = _genaroDevMultisig;
      price = _price;
      capCommitment = _capCommitment;
  }

  // @notice Deploy GNR is called only once to setup all the needed contracts.
  // @param _token: Address of an instance of the GNR token
  // @param _networkPlaceholder: Address of an instance of GNRPlaceholder
  // @param _saleWallet: Address of the wallet receiving the funds of the sale

  function setGNR(address _token, address _networkPlaceholder, address _saleWallet)
           only(genaroDevMultisig)
           public {

    require(_token != 0);
    require(_networkPlaceholder != 0);
    require(_saleWallet != 0);

    // Assert that the function hasn't been called before, as activate will happen at the end
    assert(!activated[this]);

    token = GNR(_token);
    networkPlaceholder = GRPlaceholder(_networkPlaceholder);
    saleWallet = SaleWallet(_saleWallet);
    
    assert(token.controller() == address(this)); // sale is controller
    assert(networkPlaceholder.sale() ==address(this)); // placeholder has reference to Sale
    assert(networkPlaceholder.token() == address(token)); // placeholder has reference to GNR
    assert(token.totalSupply() ==0); // token is empty
    assert(saleWallet.finalBlock() == finalBlock); // final blocks must match
    assert(saleWallet.multisig() == genaroDevMultisig);  // receiving wallet must match
    assert(saleWallet.tokenSale() == address(this));  // watched token sale must be self

    // Contract activates sale as all requirements are ready
    doActivateSale(this);
  }

  // @notice Certain addresses need to call the activate function prior to the sale opening block.
  // This proves that they have checked the sale contract is legit, as well as proving
  // the capability for those addresses to interact with the contract.
  function activateSale()
           public {
    doActivateSale(msg.sender);
  }

  function doActivateSale(address _entity)
    non_zero_address(token)               // cannot activate before setting token
    only_before_sale
    private {
    activated[_entity] = true;
  }

  // @notice Whether the needed accounts have activated the sale.
  // @return Is sale activated
  function isActivated() constant public returns (bool) {
    return activated[this] && activated[genaroDevMultisig];
  }

  // @notice Get the price for a GNR token at any given block number
  // @param _blockNumber the block for which the price is requested
  // @return Number of wei-GNR for 1 wei
  // If sale isn't ongoing for that block, returns 0.

  function getPrice(address _owner, uint _blockNumber) constant public returns (uint256) {
    if (_blockNumber < initialBlock || _blockNumber >= finalBlock) return 0;

    return (price);
    //return (tokenPrice);
  }

  // @notice Genaro Dev needs to make initial token allocations for presale partners
  // This allocation has to be made before the sale is activated. Activating the sale means no more
  // arbitrary allocations are possible and expresses conformity.
  // @param _receiver: The receiver of the tokens
  // @param _amount: Amount of tokens allocated for receiver.

  function allocatePresaleTokens(address _receiver, uint _amount, uint64 cliffDate, uint64 vestingDate)
           only_before_sale_activation
           only_before_sale
           non_zero_address(_receiver)
           only(genaroDevMultisig)
           public {

    require(_amount<=6.3*(10 ** 15)); // presale 63 million GNR. No presale partner will have more than this allocated. Prevent overflows.

    assert(token.generateTokens(address(this),_amount));
    
    // vested token be sent in appropiate vesting date
    token.grantVestedTokens(_receiver, _amount, uint64(now), cliffDate, vestingDate);

    NewPresaleAllocation(_receiver, _amount);
  }

/// @dev The fallback function is called when ether is sent to the contract, it
/// simply calls `doPayment()` with the address that sent the ether as the
/// `_owner`. Payable is a required solidity modifier for functions to receive
/// ether, without this modifier functions will throw if ether is sent to them

  function () public payable {
    return doPayment(msg.sender);
  }

/////////////////
// Whitelist  controll
/////////////////

  function addToWhiteList(address _owner) 
           only(controller)
           public{
              whitelist[_owner]=true;
           }

  function removeFromWhiteList(address _owner)
           only(controller)
           public{
              whitelist[_owner]=false;
           }

  // @return true if investor is whitelisted
  function isWhitelisted(address _owner) public constant returns (bool) {
    return whitelist[_owner];
  }           

/////////////////
// Controller interface
/////////////////

/// @notice `proxyPayment()` allows the caller to send ether to the Token directly and
/// have the tokens created in an address of their choosing
/// @param _owner The address that will hold the newly created tokens

  function proxyPayment(address _owner) payable public returns (bool) {
    doPayment(_owner);
    return true;
  }

/// @notice Notifies the controller about a transfer, for this sale all
///  transfers are allowed by default and no extra notifications are needed
/// @param _from The origin of the transfer
/// @param _to The destination of the transfer
/// @param _amount The amount of the transfer
/// @return False if the controller does not authorize the transfer
  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
    // Until the sale is finalized, only allows transfers originated by the sale contract.
    // When finalizeSale is called, this function will stop being called and will always be true.
    return _from == address(this);
  }

/// @notice Notifies the controller about an approval, for this sale all
///  approvals are allowed by default and no extra notifications are needed
/// @param _owner The address that calls `approve()`
/// @param _spender The spender in the `approve()` call
/// @param _amount The amount in the `approve()` call
/// @return False if the controller does not authorize the approval
  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
    // No approve/transferFrom during the sale
    return false;
  }

/// @dev `doPayment()` is an internal function that sends the ether that this
///  contract receives to the genaroDevMultisig and creates tokens in the address of the
/// @param _owner The address that will hold the newly created tokens

  function doPayment(address _owner)
           only_during_sale_period
           only_sale_not_stopped
           only_sale_activated
           non_zero_address(_owner)
           minimum_value(dust)
           maximum_value(maxPerPersion)
           internal {

    assert(totalCollected+msg.value <= hardCap); //if past hard cap, throw

    uint256 boughtTokens = safeMul(msg.value, getPrice(_owner,getBlockNumber())); // Calculate how many tokens bought

    assert(saleWallet.send(msg.value));  //Send fund to multisig
    assert(token.generateTokens(_owner,boughtTokens));// Allocate tokens. This will fail after sale is finalized in case it is hidden cap finalized.
    
    totalCollected = safeAdd(totalCollected, msg.value); // Save total collected amount

    NewBuyer(_owner, boughtTokens, msg.value);
  }

  // @notice Function to stop sale for an emergency.
  // @dev Only Genaro Dev can do it after it has been activated.
  function emergencyStopSale()
           only_sale_activated
           only_sale_not_stopped
           only(genaroDevMultisig)
           public {

    saleStopped = true;
  }

  // @notice Function to restart stopped sale.
  // @dev Only Genaro Dev can do it after it has been disabled and sale is ongoing.
  function restartSale()
           only_during_sale_period
           only_sale_stopped
           only(genaroDevMultisig)
           public {

    saleStopped = false;
  }

  function revealCap(uint256 _cap, uint256 _cap_secure)
           only_during_sale_period
           only_sale_activated
           verify_cap(_cap, _cap_secure)
           public {

    require(_cap <= hardCap);

    hardCap = _cap;
    CapRevealed(_cap, _cap_secure, msg.sender);

    if (totalCollected + dust >= hardCap) {
      doFinalizeSale(_cap, _cap_secure);
    }
  }

  // @notice Finalizes sale generating the tokens for Genaro Dev.
  // @dev Transfers the token controller power to the GRPlaceholder.
  function finalizeSale(uint256 _cap, uint256 _cap_secure)
           only_after_sale
           only(genaroDevMultisig)
           public {

    doFinalizeSale(_cap, _cap_secure);
  }

  function doFinalizeSale(uint256 _cap, uint256 _cap_secure)
           verify_cap(_cap, _cap_secure)
           internal {
    // Doesn't check if saleStopped is false, because sale could end in a emergency stop.
    // This function cannot be successfully called twice, because it will top being the controller,
    // and the generateTokens call will fail if called again.

    // Genaro Dev owns 5% of the total number of emitted tokens at the end of the sale.
    
    // uint256 genaroTokens = token.totalSupply() * 1 / 20; 
    // assert(token.generateTokens(genaroDevMultisig,genaroTokens));

    token.changeController(networkPlaceholder); // Sale loses token controller power in favor of network placeholder

    saleFinalized = true;  // Set stop is true which will enable network deployment
    saleStopped = true;
  }

  // @notice Deploy Genaro Network contract.
  // @param networkAddress: The address the network was deployed at.
  function deployNetwork(address networkAddress)
           only_finalized_sale
           non_zero_address(networkAddress)
           only(genaroDevMultisig)
           public {

    networkPlaceholder.changeController(networkAddress);
  }

  function setGenaroDevMultisig(address _newMultisig)
           non_zero_address(_newMultisig)
           only(genaroDevMultisig)
           public {

    genaroDevMultisig = _newMultisig;
  }

  function getBlockNumber() constant internal returns (uint) {
    return block.number;
  }

  function computeCap(uint256 _cap, uint256 _cap_secure) constant public returns (bytes32) {
    return sha3(_cap, _cap_secure);
  }

  function isValidCap(uint256 _cap, uint256 _cap_secure) constant public returns (bool) {
    return computeCap(_cap, _cap_secure) == capCommitment;
  }

  modifier only(address x) {
    require(msg.sender == x);
    _;
  }

  modifier verify_cap(uint256 _cap, uint256 _cap_secure) {
    require(isValidCap(_cap,_cap_secure));
    _;
  }

  modifier only_before_sale {
    require(getBlockNumber() < initialBlock);
    _;
  }

  modifier only_during_sale_period {
    require(getBlockNumber() >= initialBlock);
    require(getBlockNumber() < finalBlock);
    _;
  }

  modifier only_after_sale {
    require(getBlockNumber() >= finalBlock);
    _;
  }

  modifier only_sale_stopped {
    require(saleStopped);
    _;
  }

  modifier only_sale_not_stopped {
    require(!saleStopped);
    _;
  }

  modifier only_before_sale_activation {
    require(!isActivated());
    _;
  }

  modifier only_sale_activated {
    require(isActivated());
    _;
  }

  modifier only_finalized_sale {
    require(getBlockNumber() >= finalBlock);
    require(saleFinalized);
    _;
  }

  modifier non_zero_address(address x) {
    require(x != 0);
    _;
  }

  modifier maximum_value(uint256 x) {
    require(msg.value <= x);
    _;
  }

  modifier minimum_value(uint256 x) {
    require(msg.value >= x);
    _;
  }
}
