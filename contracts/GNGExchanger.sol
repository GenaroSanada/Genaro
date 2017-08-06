pragma solidity ^0.4.13;

import "./interface/Owned.sol";
import "./interface/Controller.sol";
import "zeppelin/SafeMath.sol";
import "./GenaroTokenSale.sol";
import "./GNR.sol";
import "./GNG.sol";
import "./MiniMeToken.sol";

contract GNGExchanger is Controller, Owned, SafeMath {

	mapping(address =>uint256) public collected;
	GNG public gng;
	GNR public gnr;

	GenaroTokenSale public genaroTokenSale;

	function GNGExchanger(address _gng, address _gnr, address _genaroTokenSale){
		gng = GNG(_gng);
		gnr = GNR(_gnr);
		genaroTokenSale = GenaroTokenSale(_genaroTokenSale);
	}

	/// @notice This method should be called by GNG holders to collect their 
	///	corresponding GNR

	function collect() public{

		uint256 finalizedBlock = genaroTokenSale.finalBlock();

		require(finalizedBlock !=0);
		require(getBlockNumber()>finalizedBlock);
		
		require(gng.transfersEnabled());

		uint256 balance = gng.balanceOfAt(msg.sender,finalizedBlock);

		/// @notice the decimals of GNG is 1 and the decimals of of GNR is 9 so the amount 
		/// of GNG should multiply by 10 ** 8 to get GNR amount;
		uint256 amount = safeMul(balance,10 ** 8);

		//check if the amount has been collected
		amount = safeSub(amount,collected[msg.sender]);
		assert(amount > 0);

		// the amount should transfer to GNR

		collected[msg.sender] = safeAdd(collected[msg.sender],amount);

		assert(gnr.transfer(msg.sender,amount));

		TokensCollected(msg.sender, amount);
	}

	function proxyPayment(address) public payable returns(bool){
		throw;
	}

	function onTransfer(address, address, uint256) public returns (bool){
		return false;
	}

	function onApprove(address, address, uint256) public returns(bool){
		return false;
	}

    //////////
    // Testing specific methods
    //////////

    /// @notice This function is overridden by the test Mocks.
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }	

    //////////
    // Safety Method
    //////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(gnr));
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event TokensCollected(address indexed _holder, uint256 _amount);    
}