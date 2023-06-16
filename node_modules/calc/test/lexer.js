var lexer = require('../lib/lexer');

var tokens = lexer.tokenize("4 + 4");

console.log(tokens);
