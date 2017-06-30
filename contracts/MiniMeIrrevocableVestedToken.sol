pragma solidity ^0.4.13;

// inspired by Zeppelin's Vested Token deriving MiniMeToken

import "./MiniMeToken.sol";
import "zeppelin/SafeMath.sol";

// @dev MiniMeIrrevocableVestedToken is a derived version of MiniMeToken adding the
// ability to createTokenGrants which are basically a transfer that limits the
// receiver of the tokens.


contract MiniMeIrrevocableVestedToken is MiniMeToken, SafeMath {

  uint256 MAX_GRANTS_PER_ADDRESS = 20;

  // Keep the struct at 3 sstores ( total value  20+32+24 =76 bytes)
  struct TokenGrant {
    address granter;  // 20 bytes
    uint256 value;    // 32 bytes
    uint64 cliff;
    uint64 vesting;
    uint64 start;     // 3*8 =24 bytes
  }

  event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint64 start, uint64 cliff, uint64 vesting);

  mapping (address => TokenGrant[]) public grants;

  mapping (address => bool) canCreateGrants;
  address vestingWhitelister;

  modifier canTransfer(address _sender, uint _value) {
    require(_value<=spendableBalanceOf(_sender));
    _;
  }

  modifier onlyVestingWhitelister {
    require(msg.sender==vestingWhitelister);
    _;
  }

  function MiniMeIrrevocableVestedToken (
      address _tokenFactory,
      address _parentToken,
      uint _parentSnapShotBlock,
      string _tokenName,
      uint8 _decimalUnits,
      string _tokenSymbol,
      bool _transfersEnabled
  ) MiniMeToken(_tokenFactory, _parentToken, _parentSnapShotBlock, _tokenName, _decimalUnits, _tokenSymbol, _transfersEnabled) {
    vestingWhitelister = msg.sender;
    doSetCanCreateGrants(vestingWhitelister, true);
  }

  // @dev Checks modifier and allows transfer if tokens are not locked.
  function transfer(address _to, uint _value)
           canTransfer(msg.sender, _value)
           public
           returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value)
           canTransfer(_from, _value)
           public
           returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  function spendableBalanceOf(address _holder) constant public returns (uint) {
    return transferableTokens(_holder, uint64(now));
  }

  // main func for token grant

  function grantVestedTokens(
    address _to,
    uint256 _value,
    uint64 _start,
    uint64 _cliff,
    uint64 _vesting) public {

    // Check start, cliff and vesting are properly order to ensure correct functionality of the formula.
    require(_cliff >= _start && _vesting >= _cliff);
    require(tokenGrantsCount(_to)<=MAX_GRANTS_PER_ADDRESS); //// To prevent a user being spammed and have his balance locked (out of gas attack when calculating vesting).

    assert(canCreateGrants[msg.sender]);


    TokenGrant memory grant = TokenGrant(msg.sender, _value, _cliff, _vesting, _start);
    grants[_to].push(grant);

    assert(transfer(_to,_value));

    NewTokenGrant(msg.sender, _to, _value, _cliff, _vesting, _start);
  }

  function setCanCreateGrants(address _addr, bool _allowed)
           onlyVestingWhitelister public {
    doSetCanCreateGrants(_addr, _allowed);
  }

  function doSetCanCreateGrants(address _addr, bool _allowed)
           internal {
    canCreateGrants[_addr] = _allowed;
  }

  function changeVestingWhitelister(address _newWhitelister) onlyVestingWhitelister public {
    doSetCanCreateGrants(vestingWhitelister, false);
    vestingWhitelister = _newWhitelister;
    doSetCanCreateGrants(vestingWhitelister, true);
  }

  function tokenGrantsCount(address _holder) constant public returns (uint index) {
    return grants[_holder].length;
  }

  function tokenGrant(address _holder, uint _grantId) constant public returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting) {
    TokenGrant storage grant = grants[_holder][_grantId];

    granter = grant.granter;
    value = grant.value;
    start = grant.start;
    cliff = grant.cliff;
    vesting = grant.vesting;

    // remove grant from array
 //   delete grants[_holder][_grantId];
 //   grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
 //   grants[_holder].length -= 1;

    vested = vestedTokens(grant, uint64(now));
  }

  function vestedTokens(TokenGrant grant, uint64 time) internal constant returns (uint256) {
    return calculateVestedTokens(
      grant.value,
      uint256(time),
      uint256(grant.start),
      uint256(grant.cliff),
      uint256(grant.vesting)
    );
  }

  //  transferableTokens
  //   |                         _/--------   NonVestedTokens
  //   |                       _/
  //   |                     _/
  //   |                   _/
  //   |                 _/
  //   |                /
  //   |              .|
  //   |            .  |
  //   |          .    |
  //   |        .      |
  //   |      .        |
  //   |    .          |
  //   +===+===========+---------+----------> time
  //      Start       Cliff    Vesting

  function calculateVestedTokens(
    uint256 tokens,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) internal constant returns (uint256)
    {

    // Shortcuts for before cliff and after vesting cases.
    if (time < cliff) return 0;
    if (time >= vesting) return tokens;

    // Interpolate all vested tokens.
    // As before cliff the shortcut returns 0, we can use just this function to
    // calculate it.

    // vestedTokens = tokens * (time - start) / (vesting - start)
    uint256 vestedTokens = safeDiv(
                                  safeMul(
                                    tokens,
                                    safeSub(time, start)
                                    ),
                                  safeSub(vesting, start)
                                  );

    return vestedTokens;
  }

  function nonVestedTokens(TokenGrant grant, uint64 time) internal constant returns (uint256) {
    return safeSub(grant.value, vestedTokens(grant, time));
  }

  // @dev The date in which all tokens are transferable for the holder
  // Useful for displaying purposes (not used in any logic calculations)
  function lastTokenIsTransferableDate(address holder) constant public returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = tokenGrantsCount(holder);
    for (uint256 i = 0; i < grantIndex; i++) {
      date = max64(grants[holder][i].vesting, date);
    }
    return date;
  }

  // @dev How many tokens can a holder transfer at a point in time
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);

    if (grantIndex == 0) return balanceOf(holder); // shortcut for holder without grants

    // Iterate through all the grants the holder has, and add all non-vested tokens
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = safeAdd(nonVested, nonVestedTokens(grants[holder][i], time));
    }

    // Balance - totalNonVested is the amount of tokens a holder can transfer at any given time
    return safeSub(balanceOf(holder), nonVested);
  }
}