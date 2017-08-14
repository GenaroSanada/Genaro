module.exports = function(error) {
  assert.isAbove(error.message.search('invalid opcode'), -1, 'Invalid JUMP error must be returned');
}
